import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking

public struct PushClientFactory {
    public static func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, relayClient: RelayClient) -> PushClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let serializer = Serializer(kms: kms)
        let kv = RuntimeKeyValueStorage()
        let historyStorage = CodableStore<RPCHistory.Record>(defaults: kv, identifier: "")
        let history = RPCHistory(keyValueStore: historyStorage)


        let networkingInt = NetworkingInteractor(relayClient: relayClient, serializer: serializer, logger: logger, rpcHistory: history)



        return PushClient(networkingInteractor: networkingInt, logger: logger, kms: kms)
    }
}
