import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking

public struct PushClientFactory {
    public static func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, relayClient: RelayClient) -> PushClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let serializer = Serializer(kms: kms)
        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)

        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serializer, logger: logger, rpcHistory: history)

        let pushProposer = PushProposer(networkingInteractor: networkingInteractor, kms: kms, logger: logger)
        return PushClient(networkInteractor: networkingInteractor, logger: logger, kms: kms, pushProposer: pushProposer)
    }
}
