import Foundation
import WalletConnectPairing

public struct DappPushClientFactory {

    public static func create(metadata: AppMetadata, networkInteractor: NetworkInteracting) -> DappPushClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return DappPushClientFactory.create(
            metadata: metadata,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            networkInteractor: networkInteractor
        )
    }

    static func create(metadata: AppMetadata, logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkInteractor: NetworkInteracting) -> DappPushClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let subscriptionStore = CodableStore<PushSubscription>(defaults: keyValueStorage, identifier: PushStorageIdntifiers.pushSubscription)
        let subscriptionProvider = SubscriptionsProvider(store: subscriptionStore)
        let deletePushSubscriptionSubscriber = DeletePushSubscriptionSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, pushSubscriptionStore: subscriptionStore)
        let resubscribeService = PushResubscribeService(networkInteractor: networkInteractor, subscriptionsStorage: subscriptionStore)
        let notifyProposer = NotifyProposer(networkingInteractor: networkInteractor, kms: kms, appMetadata: metadata, logger: logger)
        let notifyProposeResponseSubscriber = NotifyProposeResponseSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, metadata: metadata)
        return DappPushClient(
            logger: logger,
            kms: kms,
            subscriptionsProvider: subscriptionProvider,
            deletePushSubscriptionSubscriber: deletePushSubscriptionSubscriber,
            resubscribeService: resubscribeService,
            notifyProposer: notifyProposer,
            notifyProposeResponseSubscriber: notifyProposeResponseSubscriber
        )
    }
}
