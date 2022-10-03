import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import Foundation

public class Networking {

    /// Relay client instance
    public static var instance: NetworkingInteractor = {
        guard let config = Networking.config else {
            fatalError("Error - you must call Networking.configure(_:) before accessing the shared instance.")
        }

        return NetworkingClientFactory.create(relayClient: Relay.instance)
    }()

    private static var config: Config?

    private init() { }

    /// Relay instance config method
    /// - Parameters:
    ///   - relayHost: relay host
    ///   - projectId: project id
    ///   - socketFactory: web socket factory
    ///   - socketConnectionType: socket connection type
    static public func configure(
        relayHost: String = "relay.walletconnect.com",
        projectId: String,
        socketFactory: WebSocketFactory,
        socketConnectionType: SocketConnectionType = .automatic
    ) {
        Networking.config = Networking.Config(
            relayHost: relayHost,
            projectId: projectId,
            socketFactory: socketFactory,
            socketConnectionType: socketConnectionType
        )
        Networking.configure(
            relayHost: relayHost,
            projectId: projectId,
            socketFactory: socketFactory,
            socketConnectionType: socketConnectionType)
    }
}

extension Networking {
    struct Config {
        let relayHost: String
        let projectId: String
        let socketFactory: WebSocketFactory
        let socketConnectionType: SocketConnectionType
    }
}

public struct NetworkingClientFactory {

    public static func create(relayClient: RelayClient) -> NetworkingInteractor {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return NetworkingClientFactory.create(relayClient: relayClient, logger: logger, keychainStorage: keychainStorage, keyValueStorage: keyValueStorage)
    }

    public static func create(relayClient: RelayClient, logger: ConsoleLogging, keychainStorage: KeychainStorageProtocol, keyValueStorage: KeyValueStorage) -> NetworkingInteractor{
        let kms = KeyManagementService(keychain: keychainStorage)

        let serializer = Serializer(kms: kms)

        let rpcHistory = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)

        return NetworkingInteractor(
            relayClient: relayClient,
            serializer: serializer,
            logger: logger,
            rpcHistory: rpcHistory)
    }
}
