import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking

public struct PairingClientFactory {

    public static func create(relayClient: RelayClient) -> PairingClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return PairingClientFactory.create(logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, relayClient: relayClient)
    }

    static func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, relayClient: RelayClient) -> PairingClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let serializer = Serializer(kms: kms)
        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serializer, logger: logger, rpcHistory: history)
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: "")))
        let appPairService = AppPairService(networkingInteractor: networkingInteractor, kms: kms, pairingStorage: pairingStore)
        let walletPairService = WalletPairService(networkingInteractor: networkingInteractor, kms: kms, pairingStorage: pairingStore)
        let pairingRequestsSubscriber = PairingRequestsSubscriber(networkingInteractor: networkingInteractor, pairingStorage: pairingStore, logger: logger)

        return PairingClient(
            appPairService: appPairService,
            networkingInteractor: networkingInteractor,
            logger: logger,
            walletPairService: walletPairService,
            pairingRequestsSubscriber: pairingRequestsSubscriber,
            socketConnectionStatusPublisher: relayClient.socketConnectionStatusPublisher
        )
    }
}

