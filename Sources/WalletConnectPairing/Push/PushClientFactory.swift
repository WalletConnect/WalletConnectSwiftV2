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
        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: kv)


        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serializer, logger: logger, rpcHistory: history)

        let protocolMethod = PushProtocolMethod.propose
        let pushProposer = PushProposer(networkingInteractor: networkingInteractor, kms: kms, logger: logger, protocolMethod: protocolMethod)
        return PushClient(networkingInteractor: networkingInteractor, logger: logger, kms: kms, protocolMethod: protocolMethod, pushProposer: pushProposer)
    }
}
