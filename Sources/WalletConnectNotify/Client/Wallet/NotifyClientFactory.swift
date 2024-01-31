import Foundation

public struct NotifyClientFactory {

    public static func create(projectId: String, groupIdentifier: String, networkInteractor: NetworkInteracting, pushClient: PushClient, crypto: CryptoProvider, notifyHost: String, explorerHost: String) -> NotifyClient {
        let logger = ConsoleLogger(prefix: "🔔",loggingLevel: .debug)
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk", accessGroup: groupIdentifier)
        let groupKeychainService = GroupKeychainStorage(serviceIdentifier: groupIdentifier)
        let sqlite = NotifySqliteFactory.create(appGroup: groupIdentifier)

        return NotifyClientFactory.create(
            projectId: projectId,
            keyserverURL: keyserverURL,
            sqlite: sqlite,
            logger: logger,
            keychainStorage: keychainStorage,
            groupKeychainStorage: groupKeychainService,
            networkInteractor: networkInteractor,
            pushClient: pushClient,
            crypto: crypto,
            notifyHost: notifyHost,
            explorerHost: explorerHost
        )
    }

    static func create(
        projectId: String,
        keyserverURL: URL,
        sqlite: Sqlite,
        logger: ConsoleLogging,
        keychainStorage: KeychainStorageProtocol,
        groupKeychainStorage: KeychainStorageProtocol,
        networkInteractor: NetworkInteracting,
        pushClient: PushClient,
        crypto: CryptoProvider,
        notifyHost: String,
        explorerHost: String
    ) -> NotifyClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let notifyAccountProvider = NotifyAccountProvider()
        let database = NotifyDatabase(sqlite: sqlite, logger: logger)
        let notifyStorage = NotifyStorage(database: database, accountProvider: notifyAccountProvider)
        let identityClient = IdentityClientFactory.create(keyserver: keyserverURL, keychain: keychainStorage, logger: logger)
        let notifyMessageSubscriber = NotifyMessageSubscriber(keyserver: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, notifyStorage: notifyStorage, crypto: crypto, logger: logger)
        let webDidResolver = NotifyWebDidResolver()
        let notifyDeleteSubscriptionRequester = NotifyDeleteSubscriptionRequester(keyserver: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, logger: logger, notifyStorage: notifyStorage)
        let resubscribeService = NotifyResubscribeService(networkInteractor: networkInteractor, notifyStorage: notifyStorage, logger: logger)

        let notifyConfigProvider = NotifyConfigProvider(projectId: projectId, explorerHost: explorerHost)

        let notifySubscribeRequester = NotifySubscribeRequester(keyserverURL: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, logger: logger, kms: kms, webDidResolver: webDidResolver, notifyConfigProvider: notifyConfigProvider)

        let notifySubscriptionsUpdater = NotifySubsctiptionsUpdater(networkingInteractor: networkInteractor, kms: kms, logger: logger, notifyStorage: notifyStorage, groupKeychainStorage: groupKeychainStorage)

        let notifySubscriptionsBuilder = NotifySubscriptionsBuilder(notifyConfigProvider: notifyConfigProvider)

        let notifySubscribeResponseSubscriber = NotifySubscribeResponseSubscriber(networkingInteractor: networkInteractor, logger: logger, notifySubscriptionsBuilder: notifySubscriptionsBuilder, notifySubscriptionsUpdater: notifySubscriptionsUpdater)

        let notifyUpdateRequester = NotifyUpdateRequester(keyserverURL: keyserverURL, identityClient: identityClient, networkingInteractor: networkInteractor, notifyConfigProvider: notifyConfigProvider, logger: logger, notifyStorage: notifyStorage)

        let notifyUpdateResponseSubscriber = NotifyUpdateResponseSubscriber(networkingInteractor: networkInteractor, logger: logger, notifySubscriptionsBuilder: notifySubscriptionsBuilder, notifySubscriptionsUpdater: notifySubscriptionsUpdater)

        let subscriptionsAutoUpdater = SubscriptionsAutoUpdater(notifyUpdateRequester: notifyUpdateRequester, logger: logger, notifyStorage: notifyStorage)

        let notifyWatcherAgreementKeysProvider = NotifyWatcherAgreementKeysProvider(kms: kms)
        let notifyWatchSubscriptionsRequester = NotifyWatchSubscriptionsRequester(keyserverURL: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, logger: logger, webDidResolver: webDidResolver, notifyAccountProvider: notifyAccountProvider, notifyWatcherAgreementKeysProvider: notifyWatcherAgreementKeysProvider, notifyHost: notifyHost)
        let notifyWatchSubscriptionsResponseSubscriber = NotifyWatchSubscriptionsResponseSubscriber(networkingInteractor: networkInteractor, logger: logger, notifySubscriptionsBuilder: notifySubscriptionsBuilder, notifySubscriptionsUpdater: notifySubscriptionsUpdater)
        let notifySubscriptionsChangedRequestSubscriber = NotifySubscriptionsChangedRequestSubscriber(keyserver: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, logger: logger, notifySubscriptionsUpdater: notifySubscriptionsUpdater, notifySubscriptionsBuilder: notifySubscriptionsBuilder)
        let subscriptionWatcher = SubscriptionWatcher(notifyWatchSubscriptionsRequester: notifyWatchSubscriptionsRequester, logger: logger)
        let historyService = HistoryService(keyserver: keyserverURL, networkingClient: networkInteractor, identityClient: identityClient)
        let notifyDeleteSubscriptionSubscriber = NotifyDeleteSubscriptionSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, notifySubscriptionsBuilder: notifySubscriptionsBuilder, notifySubscriptionsUpdater: notifySubscriptionsUpdater)

        return NotifyClient(
            logger: logger,
            keyserverURL: keyserverURL,
            kms: kms,
            identityClient: identityClient, 
            historyService: historyService,
            pushClient: pushClient,
            notifyMessageSubscriber: notifyMessageSubscriber,
            notifyStorage: notifyStorage,
            notifyDeleteSubscriptionRequester: notifyDeleteSubscriptionRequester,
            resubscribeService: resubscribeService,
            notifySubscribeRequester: notifySubscribeRequester,
            notifySubscribeResponseSubscriber: notifySubscribeResponseSubscriber, 
            notifyDeleteSubscriptionSubscriber: notifyDeleteSubscriptionSubscriber,
            notifyUpdateRequester: notifyUpdateRequester,
            notifyUpdateResponseSubscriber: notifyUpdateResponseSubscriber,
            notifyAccountProvider: notifyAccountProvider,
            subscriptionsAutoUpdater: subscriptionsAutoUpdater,
            notifyWatchSubscriptionsResponseSubscriber: notifyWatchSubscriptionsResponseSubscriber, 
            notifyWatcherAgreementKeysProvider: notifyWatcherAgreementKeysProvider,
            notifySubscriptionsChangedRequestSubscriber: notifySubscriptionsChangedRequestSubscriber, 
            notifySubscriptionsUpdater: notifySubscriptionsUpdater,
            subscriptionWatcher: subscriptionWatcher
        )
    }
}
