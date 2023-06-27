import Foundation

public struct DappPushClientFactory {

    public static func create(metadata: AppMetadata, networkInteractor: NetworkInteracting, syncClient: SyncClient) -> DappPushClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return DappPushClientFactory.create(
            metadata: metadata,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            networkInteractor: networkInteractor,
            syncClient: syncClient
        )
    }

    static func create(metadata: AppMetadata, logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkInteractor: NetworkInteracting, syncClient: SyncClient) -> DappPushClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let subscriptionStore: SyncStore<PushSubscription> = SyncStoreFactory.create(name: PushStorageIdntifiers.pushSubscription, syncClient: syncClient, storage: keyValueStorage)

        let subscriptionStoreDelegate = PushSubscriptionStoreDelegate(networkingInteractor: networkInteractor, kms: kms)
        let pushStorage = PushStorage(subscriptionStore: subscriptionStore, subscriptionStoreDelegate: subscriptionStoreDelegate)
        let deletePushSubscriptionSubscriber = DeletePushSubscriptionSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, pushStorage: pushStorage)
        let resubscribeService = PushResubscribeService(networkInteractor: networkInteractor, pushStorage: pushStorage)
        let notifyProposer = NotifyProposer(networkingInteractor: networkInteractor, kms: kms, appMetadata: metadata, logger: logger)
        let notifyProposeResponseSubscriber = NotifyProposeResponseSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, metadata: metadata)
        return DappPushClient(
            logger: logger,
            kms: kms,
            pushStorage: pushStorage,
            deletePushSubscriptionSubscriber: deletePushSubscriptionSubscriber,
            resubscribeService: resubscribeService,
            notifyProposer: notifyProposer,
            notifyProposeResponseSubscriber: notifyProposeResponseSubscriber
        )
    }
}
