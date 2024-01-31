import Foundation

public struct PairingClientFactory {

    public static func create(
        networkingClient: NetworkingInteractor,
        groupIdentifier: String
    ) -> PairingClient {
        let logger = ConsoleLogger(loggingLevel: .off)

        guard let keyValueStorage = UserDefaults(suiteName: groupIdentifier) else {
            fatalError("Could not instantiate UserDefaults for a group identifier \(groupIdentifier)")
        }
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk", accessGroup: groupIdentifier)

        return PairingClientFactory.create(logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, networkingClient: networkingClient)
    }

    public static func create(
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage,
        keychainStorage: KeychainStorageProtocol,
        networkingClient: NetworkingInteractor
    ) -> PairingClient {
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: PairStorageIdentifiers.pairings.rawValue)))
        let kms = KeyManagementService(keychain: keychainStorage)
        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let appPairService = AppPairService(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore)
        let walletPairService = WalletPairService(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore, history: history, logger: logger)
        let pairingRequestsSubscriber = PairingRequestsSubscriber(networkingInteractor: networkingClient, pairingStorage: pairingStore, logger: logger)
        let pairingsProvider = PairingsProvider(pairingStorage: pairingStore)
        let cleanupService = PairingCleanupService(pairingStore: pairingStore, kms: kms)
        let pairingDeleteRequester = PairingDeleteRequester(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore, logger: logger)
        let pingService = PairingPingService(pairingStorage: pairingStore, networkingInteractor: networkingClient, logger: logger)
        let appPairActivateService = AppPairActivationService(pairingStorage: pairingStore, logger: logger)
        let expirationService = ExpirationService(pairingStorage: pairingStore, networkInteractor: networkingClient, kms: kms)
        let resubscribeService = PairingResubscribeService(networkInteractor: networkingClient, pairingStorage: pairingStore)
        let pairingDeleteRequestSubscriber = PairingDeleteRequestSubscriber(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore, logger: logger)
        let pairingStateProvider = PairingStateProvider(pairingStorage: pairingStore)

        return PairingClient(
            pairingStorage: pairingStore,
            appPairService: appPairService,
            networkingInteractor: networkingClient,
            logger: logger,
            walletPairService: walletPairService,
            pairingDeleteRequester: pairingDeleteRequester,
            pairingDeleteRequestSubscriber: pairingDeleteRequestSubscriber,
            resubscribeService: resubscribeService,
            expirationService: expirationService,
            pairingRequestsSubscriber: pairingRequestsSubscriber,
            appPairActivateService: appPairActivateService,
            cleanupService: cleanupService,
            pingService: pingService,
            socketConnectionStatusPublisher: networkingClient.socketConnectionStatusPublisher,
            pairingsProvider: pairingsProvider,
            pairingStateProvider: pairingStateProvider
        )
    }
}
