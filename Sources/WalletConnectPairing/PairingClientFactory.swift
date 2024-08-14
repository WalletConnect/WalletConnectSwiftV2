import Foundation

public struct PairingClientFactory {

    public static func create(
        networkingClient: NetworkingInteractor,
        eventsClient: EventsClient,
        groupIdentifier: String
    ) -> PairingClient {
        let logger = ConsoleLogger(loggingLevel: .off)

        guard let keyValueStorage = UserDefaults(suiteName: groupIdentifier) else {
            fatalError("Could not instantiate UserDefaults for a group identifier \(groupIdentifier)")
        }
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk", accessGroup: groupIdentifier)

        return PairingClientFactory.create(logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, networkingClient: networkingClient, eventsClient: eventsClient)
    }

    public static func create(
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage,
        keychainStorage: KeychainStorageProtocol,
        networkingClient: NetworkingInteractor,
        eventsClient: EventsClientProtocol
    ) -> PairingClient {
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: PairStorageIdentifiers.pairings.rawValue)))
        let kms = KeyManagementService(keychain: keychainStorage)
        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let appPairService = AppPairService(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore)
        let walletPairService = WalletPairService(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore, history: history, logger: logger, eventsClient: eventsClient)
        let pairingRequestsSubscriber = PairingRequestsSubscriber(networkingInteractor: networkingClient, pairingStorage: pairingStore, logger: logger)
        let pairingsProvider = PairingsProvider(pairingStorage: pairingStore)
        let cleanupService = PairingCleanupService(pairingStore: pairingStore, kms: kms)
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
            pairingDeleteRequestSubscriber: pairingDeleteRequestSubscriber,
            resubscribeService: resubscribeService,
            expirationService: expirationService,
            pairingRequestsSubscriber: pairingRequestsSubscriber,
            cleanupService: cleanupService,
            socketConnectionStatusPublisher: networkingClient.socketConnectionStatusPublisher,
            pairingsProvider: pairingsProvider,
            pairingStateProvider: pairingStateProvider
        )
    }
}
