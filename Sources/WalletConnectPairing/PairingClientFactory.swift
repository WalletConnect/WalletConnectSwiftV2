import Foundation

public struct PairingClientFactory {

    public static func create(networkingClient: NetworkingInteractor) -> PairingClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return PairingClientFactory.create(logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, networkingClient: networkingClient)
    }

    public static func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkingClient: NetworkingInteractor) -> PairingClient {
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: PairStorageIdentifiers.pairings.rawValue)))
        let kms = KeyManagementService(keychain: keychainStorage)
        let appPairService = AppPairService(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore)
        let walletPairService = WalletPairService(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore)
        let pairingRequestsSubscriber = PairingRequestsSubscriber(networkingInteractor: networkingClient, pairingStorage: pairingStore, logger: logger)
        let pairingsProvider = PairingsProvider(pairingStorage: pairingStore)
        let cleanupService = PairingCleanupService(pairingStore: pairingStore, kms: kms)
        let deletePairingService = DeletePairingService(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore, logger: logger)
        let pingService = PairingPingService(pairingStorage: pairingStore, networkingInteractor: networkingClient, logger: logger)
        let appPairActivateService = AppPairActivationService(pairingStorage: pairingStore, logger: logger)
        let expirationService = ExpirationService(pairingStorage: pairingStore, networkInteractor: networkingClient, kms: kms)
        let resubscribeService = PairingResubscribeService(networkInteractor: networkingClient, pairingStorage: pairingStore)

        return PairingClient(
            appPairService: appPairService,
            networkingInteractor: networkingClient,
            logger: logger,
            walletPairService: walletPairService,
            deletePairingService: deletePairingService,
            resubscribeService: resubscribeService,
            expirationService: expirationService,
            pairingRequestsSubscriber: pairingRequestsSubscriber,
            appPairActivateService: appPairActivateService,
            cleanupService: cleanupService,
            pingService: pingService,
            socketConnectionStatusPublisher: networkingClient.socketConnectionStatusPublisher,
            pairingsProvider: pairingsProvider
        )
    }
}
