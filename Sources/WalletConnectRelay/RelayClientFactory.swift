//     
import Foundation


public struct RelayClientFactory {

    public static func create(
        relayHost: String,
        projectId: String,
        socketFactory: WebSocketFactory,
        groupIdentifier: String,
        socketConnectionType: SocketConnectionType
    ) -> RelayClient {


        guard let keyValueStorage = UserDefaults(suiteName: groupIdentifier) else {
            fatalError("Could not instantiate UserDefaults for a group identifier \(groupIdentifier)")
        }
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk", accessGroup: groupIdentifier)

        let logger = ConsoleLogger(prefix: "🚄" ,loggingLevel: .off)

        let networkMonitor = NetworkMonitor()

        return RelayClientFactory.create(
            relayHost: relayHost,
            projectId: projectId,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            socketFactory: socketFactory,
            socketConnectionType: socketConnectionType,
            networkMonitor: networkMonitor,
            logger: logger
        )
    }


    public static func create(
        relayHost: String,
        projectId: String,
        keyValueStorage: KeyValueStorage,
        keychainStorage: KeychainStorageProtocol,
        socketFactory: WebSocketFactory,
        socketConnectionType: SocketConnectionType = .automatic,
        networkMonitor: NetworkMonitoring,
        logger: ConsoleLogging
    ) -> RelayClient {

        let clientIdStorage = ClientIdStorage(defaults: keyValueStorage, keychain: keychainStorage, logger: logger)

        let socketAuthenticator = ClientIdAuthenticator(
            clientIdStorage: clientIdStorage
        )
        let relayUrlFactory = RelayUrlFactory(
            relayHost: relayHost,
            projectId: projectId,
            socketAuthenticator: socketAuthenticator
        )
        let socket = socketFactory.create(with: relayUrlFactory.create())
        socket.request.addValue(EnvironmentInfo.userAgent, forHTTPHeaderField: "User-Agent")
        if let bundleId = Bundle.main.bundleIdentifier {
            socket.request.addValue(bundleId, forHTTPHeaderField: "Origin")
        }

        var socketConnectionHandler: SocketConnectionHandler!
        switch socketConnectionType {
        case .automatic:    socketConnectionHandler = AutomaticSocketConnectionHandler(socket: socket, logger: logger)
        case .manual:       socketConnectionHandler = ManualSocketConnectionHandler(socket: socket, logger: logger)
        }

        let dispatcher = Dispatcher(
            socketFactory: socketFactory,
            relayUrlFactory: relayUrlFactory,
            networkMonitor: networkMonitor,
            socket: socket,
            logger: logger,
            socketConnectionHandler: socketConnectionHandler
        )

        let rpcHistory = RPCHistoryFactory.createForRelay(keyValueStorage: keyValueStorage)

        return RelayClient(dispatcher: dispatcher, logger: logger, rpcHistory: rpcHistory, clientIdStorage: clientIdStorage)
    }
}
