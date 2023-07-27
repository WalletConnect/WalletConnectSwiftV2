import Foundation

public struct NotifyClientFactory {

    public static func create(networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer, pushClient: PushClient, syncClient: SyncClient, historyClient: HistoryClient) -> NotifyClient {
        let logger = ConsoleLogger(suffix: "🔔",loggingLevel: .debug)
        let keyValueStorage = UserDefaults.standard
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        let groupKeychainService = GroupKeychainStorage(serviceIdentifier: "group.com.walletconnect.sdk")

        return NotifyClientFactory.create(
            keyserverURL: keyserverURL,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            groupKeychainStorage: groupKeychainService,
            networkInteractor: networkInteractor,
            pairingRegisterer: pairingRegisterer,
            pushClient: pushClient,
            syncClient: syncClient,
            historyClient: historyClient
        )
    }

    static func create(
        keyserverURL: URL,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage,
        keychainStorage: KeychainStorageProtocol,
        groupKeychainStorage: KeychainStorageProtocol,
        networkInteractor: NetworkInteracting,
        pairingRegisterer: PairingRegisterer,
        pushClient: PushClient,
        syncClient: SyncClient,
        historyClient: HistoryClient
    ) -> NotifyClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let subscriptionStore: SyncStore<NotifySubscription> = SyncStoreFactory.create(name: NotifyStorageIdntifiers.notifySubscription, syncClient: syncClient, storage: keyValueStorage)
        let subscriptionStoreDelegate = NotifySubscriptionStoreDelegate(networkingInteractor: networkInteractor, kms: kms, groupKeychainStorage: groupKeychainStorage)
        let messagesStore = KeyedDatabase<NotifyMessageRecord>(storage: keyValueStorage, identifier: NotifyStorageIdntifiers.notifyMessagesRecords)
        let notifyStorage = NotifyStorage(subscriptionStore: subscriptionStore, messagesStore: messagesStore, subscriptionStoreDelegate: subscriptionStoreDelegate)
        let coldStartStore = CodableStore<Date>(defaults: keyValueStorage, identifier: NotifyStorageIdntifiers.coldStartStore)
        let notifySyncService = NotifySyncService(syncClient: syncClient, logger: logger, historyClient: historyClient, subscriptionsStore: subscriptionStore, messagesStore: messagesStore, networkingInteractor: networkInteractor, kms: kms, coldStartStore: coldStartStore, groupKeychainStorage: groupKeychainStorage)
        let identityClient = IdentityClientFactory.create(keyserver: keyserverURL, keychain: keychainStorage, logger: logger)
        let notifyMessageSubscriber = NotifyMessageSubscriber(networkingInteractor: networkInteractor, notifyStorage: notifyStorage, logger: logger)
        let deleteNotifySubscriptionService = DeleteNotifySubscriptionService(networkingInteractor: networkInteractor, kms: kms, logger: logger, notifyStorage: notifyStorage)
        let resubscribeService = NotifyResubscribeService(networkInteractor: networkInteractor, notifyStorage: notifyStorage)

        let dappsMetadataStore = CodableStore<AppMetadata>(defaults: keyValueStorage, identifier: NotifyStorageIdntifiers.dappsMetadataStore)
        let subscriptionScopeProvider = SubscriptionScopeProvider()

        let notifySubscribeRequester = NotifySubscribeRequester(keyserverURL: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, logger: logger, kms: kms, subscriptionScopeProvider: subscriptionScopeProvider, dappsMetadataStore: dappsMetadataStore)

        let notifySubscribeResponseSubscriber = NotifySubscribeResponseSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, groupKeychainStorage: groupKeychainStorage, notifyStorage: notifyStorage, dappsMetadataStore: dappsMetadataStore, subscriptionScopeProvider: subscriptionScopeProvider)

        let notifyUpdateRequester = NotifyUpdateRequester(keyserverURL: keyserverURL, identityClient: identityClient, networkingInteractor: networkInteractor, logger: logger, notifyStorage: notifyStorage)

        let notifyUpdateResponseSubscriber = NotifyUpdateResponseSubscriber(networkingInteractor: networkInteractor, logger: logger, subscriptionScopeProvider: subscriptionScopeProvider, notifyStorage: notifyStorage)

        let deleteNotifySubscriptionSubscriber = DeleteNotifySubscriptionSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, notifyStorage: notifyStorage)

        let subscriptionsAutoUpdater = SubscriptionsAutoUpdater(notifyUpdateRequester: notifyUpdateRequester, logger: logger, notifyStorage: notifyStorage)

        return NotifyClient(
            logger: logger,
            kms: kms,
            pushClient: pushClient,
            notifyMessageSubscriber: notifyMessageSubscriber,
            notifyStorage: notifyStorage,
            notifySyncService: notifySyncService,
            deleteNotifySubscriptionService: deleteNotifySubscriptionService,
            resubscribeService: resubscribeService,
            notifySubscribeRequester: notifySubscribeRequester,
            notifySubscribeResponseSubscriber: notifySubscribeResponseSubscriber,
            deleteNotifySubscriptionSubscriber: deleteNotifySubscriptionSubscriber,
            notifyUpdateRequester: notifyUpdateRequester,
            notifyUpdateResponseSubscriber: notifyUpdateResponseSubscriber,
            subscriptionsAutoUpdater: subscriptionsAutoUpdater
        )
    }
}
