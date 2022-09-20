import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking

public struct PairingClientFactory {
    public static func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, relayClient: RelayClient) -> PairingClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let serializer = Serializer(kms: kms)
        let kv = RuntimeKeyValueStorage()
        let historyStorage = CodableStore<RPCHistory.Record>(defaults: kv, identifier: "")
        let history = RPCHistory(keyValueStore: historyStorage)


        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serializer, logger: logger, rpcHistory: history)
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: kv, identifier: "")))


        let appPairService = AppPairService(networkingInteractor: networkingInteractor, kms: kms, pairingStorage: pairingStore)

        let walletPaS = WalletPairService(networkingInteractor: networkingInteractor, kms: kms, pairingStorage: pairingStore)

        let pairingRequestsSubscriber = PairingRequestsSubscriber(networkingInteractor: networkingInteractor, logger: logger, kms: kms)

        return PairingClient(appPairService: appPairService, networkingInteractor: networkingInteractor, logger: logger, walletPairService: walletPaS, pairingRequestsSubscriber: pairingRequestsSubscriber, socketConnectionStatusPublisher: relayClient.socketConnectionStatusPublisher)
    }
}

