//     
import Foundation


public struct RelayClientFactory {

    public static func create(
        relayHost: String,
        projectId: String,
        socketConnectionType: SocketConnectionType
    ) -> RelayClient {

        let keyValueStorage = UserDefaults.standard

        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")

        let logger = ConsoleLogger(suffix: "🚄" ,loggingLevel: .debug)

        return RelayClientFactory.create(
            relayHost: relayHost,
            projectId: projectId,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            socketConnectionType: socketConnectionType,
            logger: logger
        )
    }


    public static func create(
        relayHost: String,
        projectId: String,
        keyValueStorage: KeyValueStorage,
        keychainStorage: KeychainStorageProtocol,
        socketConnectionType: SocketConnectionType = .automatic,
        logger: ConsoleLogging
    ) -> RelayClient {

        let clientIdStorage = ClientIdStorage(keychain: keychainStorage)

        let socketAuthenticator = ClientIdAuthenticator(
            clientIdStorage: clientIdStorage,
            url: "wss://\(relayHost)"
        )
        let relayUrlFactory = RelayUrlFactory(
            relayHost: relayHost,
            projectId: projectId,
            socketAuthenticator: socketAuthenticator
        )
        let webSocketClientFactory = WebSocketClientFactory(logger: logger)
        let dispatcher = Dispatcher(
            socketFactory: webSocketClientFactory,
            relayUrlFactory: relayUrlFactory,
            socketConnectionType: socketConnectionType,
            logger: logger
        )

        let rpcHistory = RPCHistoryFactory.createForRelay(keyValueStorage: keyValueStorage)

        return RelayClient(dispatcher: dispatcher, logger: logger, rpcHistory: rpcHistory, clientIdStorage: clientIdStorage)
    }
}
