import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectNetworking

public struct PairingClientFactory {

    public static func create(networkingClient: NetworkingClient) -> PairingClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return PairingClientFactory.create(logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, networkingClient: networkingClient)
    }

    public static func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkingClient: NetworkingClient) -> PairingClient {
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.pairings.rawValue)))
        let kms = KeyManagementService(keychain: keychainStorage)
        let appPairService = AppPairService(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore)
        let walletPairService = WalletPairService(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore)
        let pairingRequestsSubscriber = PairingRequestsSubscriber(networkingInteractor: networkingClient, pairingStorage: pairingStore, logger: logger)
        let pairingsProvider = PairingsProvider(pairingStorage: pairingStore)
        let cleanupService = CleanupService(pairingStore: pairingStore, kms: kms)
        let deletePairingService = DeletePairingService(networkingInteractor: networkingClient, kms: kms, pairingStorage: pairingStore, logger: logger)
        let pingService = PairingPingService(pairingStorage: pairingStore, networkingInteractor: networkingClient, logger: logger)
        let appPairActivateService = AppPairActivationService(pairingStorage: pairingStore, logger: logger)
        let expirationService = ExpirationService(pairingStorage: pairingStore, networkInteractor: networkingInteractor, kms: kms)
        let resubscribeService = ResubscribeService(networkInteractor: networkingInteractor, pairingStorage: pairingStore)

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
            pairingStorage: pairingStore,
            cleanupService: cleanupService,
            pingService: pingService,
            socketConnectionStatusPublisher: networkingClient.socketConnectionStatusPublisher,
            pairingsProvider: pairingsProvider
        )
    }
}

