import Foundation
import WalletConnectKMS
import WalletConnectRelay
import WalletConnectUtils

public struct NetworkingClientFactory {

    public static func create(relayClient: RelayClient) -> NetworkingClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return NetworkingClientFactory.create(relayClient: relayClient, logger: logger, keychainStorage: keychainStorage, keyValueStorage: keyValueStorage)
    }

    public static func create(relayClient: RelayClient, logger: ConsoleLogging, keychainStorage: KeychainStorageProtocol, keyValueStorage: KeyValueStorage) -> NetworkingClient{
        let kms = KeyManagementService(keychain: keychainStorage)

        let serializer = Serializer(kms: kms)

        let rpcHistory = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)

        return NetworkingClient(
            relayClient: relayClient,
            serializer: serializer,
            logger: logger,
            rpcHistory: rpcHistory)
    }
}
