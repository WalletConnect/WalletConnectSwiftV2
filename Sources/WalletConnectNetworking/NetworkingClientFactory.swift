import Foundation

public struct NetworkingClientFactory {

    public static func create(relayClient: RelayClient) -> NetworkingInteractor {
        let logger = ConsoleLogger(loggingLevel: .debug)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return NetworkingClientFactory.create(relayClient: relayClient, logger: logger, keychainStorage: keychainStorage, keyValueStorage: keyValueStorage)
    }

    public static func create(relayClient: RelayClient, logger: ConsoleLogging, keychainStorage: KeychainStorageProtocol, keyValueStorage: KeyValueStorage) -> NetworkingInteractor {
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
