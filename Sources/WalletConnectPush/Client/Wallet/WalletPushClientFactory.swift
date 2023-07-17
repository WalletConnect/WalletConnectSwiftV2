import Foundation

public struct WalletPushClientFactory {

    public static func create(networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer, echoClient: EchoClient, syncClient: SyncClient, historyClient: HistoryClient) -> WalletPushClient {
        let logger = ConsoleLogger(suffix: "🔔",loggingLevel: .debug)
        let keyValueStorage = UserDefaults.standard
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        let groupKeychainService = GroupKeychainStorage(serviceIdentifier: "group.com.walletconnect.sdk")

        return WalletPushClientFactory.create(
            keyserverURL: keyserverURL,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            groupKeychainStorage: groupKeychainService,
            networkInteractor: networkInteractor,
            pairingRegisterer: pairingRegisterer,
            echoClient: echoClient,
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
        echoClient: EchoClient,
        syncClient: SyncClient,
        historyClient: HistoryClient
    ) -> WalletPushClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let subscriptionStore: SyncStore<PushSubscription> = SyncStoreFactory.create(name: PushStorageIdntifiers.pushSubscription, syncClient: syncClient, storage: keyValueStorage)
        let subscriptionStoreDelegate = PushSubscriptionStoreDelegate(networkingInteractor: networkInteractor, kms: kms, groupKeychainStorage: groupKeychainStorage)
        let messagesStore = KeyedDatabase<PushMessageRecord>(storage: keyValueStorage, identifier: PushStorageIdntifiers.pushMessagesRecords)
        let pushStorage = PushStorage(subscriptionStore: subscriptionStore, messagesStore: messagesStore, subscriptionStoreDelegate: subscriptionStoreDelegate)
        let coldStartStore = CodableStore<Date>(defaults: keyValueStorage, identifier: PushStorageIdntifiers.coldStartStore)
        let pushSyncService = PushSyncService(syncClient: syncClient, logger: logger, historyClient: historyClient, subscriptionsStore: subscriptionStore, messagesStore: messagesStore, networkingInteractor: networkInteractor, kms: kms, coldStartStore: coldStartStore, groupKeychainStorage: groupKeychainStorage)
        let identityClient = IdentityClientFactory.create(keyserver: keyserverURL, keychain: keychainStorage, logger: logger)
        let pushMessageSubscriber = PushMessageSubscriber(networkingInteractor: networkInteractor, pushStorage: pushStorage, logger: logger)
        let deletePushSubscriptionService = DeletePushSubscriptionService(networkingInteractor: networkInteractor, kms: kms, logger: logger, pushStorage: pushStorage)
        let resubscribeService = PushResubscribeService(networkInteractor: networkInteractor, pushStorage: pushStorage)

        let dappsMetadataStore = CodableStore<AppMetadata>(defaults: keyValueStorage, identifier: PushStorageIdntifiers.dappsMetadataStore)
        let subscriptionScopeProvider = SubscriptionScopeProvider()

        let pushSubscribeRequester = PushSubscribeRequester(keyserverURL: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, logger: logger, kms: kms, subscriptionScopeProvider: subscriptionScopeProvider, dappsMetadataStore: dappsMetadataStore)

        let pushSubscribeResponseSubscriber = PushSubscribeResponseSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, groupKeychainStorage: groupKeychainStorage, pushStorage: pushStorage, dappsMetadataStore: dappsMetadataStore, subscriptionScopeProvider: subscriptionScopeProvider)

        let notifyUpdateRequester = NotifyUpdateRequester(keyserverURL: keyserverURL, identityClient: identityClient, networkingInteractor: networkInteractor, logger: logger, pushStorage: pushStorage)

        let notifyUpdateResponseSubscriber = NotifyUpdateResponseSubscriber(networkingInteractor: networkInteractor, logger: logger, subscriptionScopeProvider: subscriptionScopeProvider, pushStorage: pushStorage)

        let deletePushSubscriptionSubscriber = DeletePushSubscriptionSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, pushStorage: pushStorage)

        let subscriptionsAutoUpdater = SubscriptionsAutoUpdater(notifyUpdateRequester: notifyUpdateRequester, logger: logger, pushStorage: pushStorage)

        return WalletPushClient(
            logger: logger,
            kms: kms,
            echoClient: echoClient,
            pushMessageSubscriber: pushMessageSubscriber,
            pushStorage: pushStorage,
            pushSyncService: pushSyncService,
            deletePushSubscriptionService: deletePushSubscriptionService,
            resubscribeService: resubscribeService,
            pushSubscribeRequester: pushSubscribeRequester,
            pushSubscribeResponseSubscriber: pushSubscribeResponseSubscriber,
            deletePushSubscriptionSubscriber: deletePushSubscriptionSubscriber,
            notifyUpdateRequester: notifyUpdateRequester,
            notifyUpdateResponseSubscriber: notifyUpdateResponseSubscriber,
            subscriptionsAutoUpdater: subscriptionsAutoUpdater
        )
    }
}
