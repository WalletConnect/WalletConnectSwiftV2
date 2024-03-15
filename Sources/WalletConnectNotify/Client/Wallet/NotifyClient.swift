import Foundation
import Combine


public class NotifyClient {

    private var publishers = Set<AnyCancellable>()

    public var subscriptionsPublisher: AnyPublisher<[NotifySubscription], Never> {
        return notifyStorage.subscriptionsPublisher
    }

    public var messagesPublisher: AnyPublisher<[NotifyMessageRecord], Never> {
        return notifyStorage.messagesPublisher
    }

    public var logsPublisher: AnyPublisher<Log, Never> {
        return logger.logsPublisher
    }

    private let notifyDeleteSubscriptionRequester: NotifyDeleteSubscriptionRequester
    private let notifySubscribeRequester: NotifySubscribeRequester

    public let logger: ConsoleLogging

    private let keyserverURL: URL
    private let pushClient: PushClient
    private let identityClient: IdentityClient
    private let historyService: HistoryService
    private let notifyStorage: NotifyStorage
    private let notifyAccountProvider: NotifyAccountProvider
    private let notifyMessageSubscriber: NotifyMessageSubscriber
    private let resubscribeService: NotifyResubscribeService
    private let notifySubscribeResponseSubscriber: NotifySubscribeResponseSubscriber
    private let notifyDeleteSubscriptionSubscriber: NotifyDeleteSubscriptionSubscriber
    private let notifyUpdateRequester: NotifyUpdateRequester
    private let notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber
    private let subscriptionsAutoUpdater: SubscriptionsAutoUpdater
    private let notifyWatchSubscriptionsResponseSubscriber: NotifyWatchSubscriptionsResponseSubscriber
    private let notifyWatcherAgreementKeysProvider: NotifyWatcherAgreementKeysProvider
    private let notifySubscriptionsChangedRequestSubscriber: NotifySubscriptionsChangedRequestSubscriber
    private let notifySubscriptionsUpdater: NotifySubsctiptionsUpdater
    private let subscriptionWatcher: SubscriptionWatcher

    init(logger: ConsoleLogging,
         keyserverURL: URL,
         kms: KeyManagementServiceProtocol,
         identityClient: IdentityClient,
         historyService: HistoryService,
         pushClient: PushClient,
         notifyMessageSubscriber: NotifyMessageSubscriber,
         notifyStorage: NotifyStorage,
         notifyDeleteSubscriptionRequester: NotifyDeleteSubscriptionRequester,
         resubscribeService: NotifyResubscribeService,
         notifySubscribeRequester: NotifySubscribeRequester,
         notifySubscribeResponseSubscriber: NotifySubscribeResponseSubscriber,
         notifyDeleteSubscriptionSubscriber: NotifyDeleteSubscriptionSubscriber,
         notifyUpdateRequester: NotifyUpdateRequester,
         notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber,
         notifyAccountProvider: NotifyAccountProvider,
         subscriptionsAutoUpdater: SubscriptionsAutoUpdater,
         notifyWatchSubscriptionsResponseSubscriber: NotifyWatchSubscriptionsResponseSubscriber,
         notifyWatcherAgreementKeysProvider: NotifyWatcherAgreementKeysProvider,
         notifySubscriptionsChangedRequestSubscriber: NotifySubscriptionsChangedRequestSubscriber,
         notifySubscriptionsUpdater: NotifySubsctiptionsUpdater,
         subscriptionWatcher: SubscriptionWatcher
    ) {
        self.logger = logger
        self.keyserverURL = keyserverURL
        self.pushClient = pushClient
        self.identityClient = identityClient
        self.historyService = historyService
        self.notifyMessageSubscriber = notifyMessageSubscriber
        self.notifyStorage = notifyStorage
        self.notifyDeleteSubscriptionRequester = notifyDeleteSubscriptionRequester
        self.resubscribeService = resubscribeService
        self.notifySubscribeRequester = notifySubscribeRequester
        self.notifySubscribeResponseSubscriber = notifySubscribeResponseSubscriber
        self.notifyDeleteSubscriptionSubscriber = notifyDeleteSubscriptionSubscriber
        self.notifyUpdateRequester = notifyUpdateRequester
        self.notifyUpdateResponseSubscriber = notifyUpdateResponseSubscriber
        self.notifyAccountProvider = notifyAccountProvider
        self.subscriptionsAutoUpdater = subscriptionsAutoUpdater
        self.notifyWatchSubscriptionsResponseSubscriber = notifyWatchSubscriptionsResponseSubscriber
        self.notifyWatcherAgreementKeysProvider = notifyWatcherAgreementKeysProvider
        self.notifySubscriptionsChangedRequestSubscriber = notifySubscriptionsChangedRequestSubscriber
        self.notifySubscriptionsUpdater = notifySubscriptionsUpdater
        self.subscriptionWatcher = subscriptionWatcher
    }

    public func prepareRegistration(account: Account, domain: String) async throws -> IdentityRegistrationParams {
        return try await identityClient.prepareRegistration(
            account: account,
            domain: domain,
            resources: [keyserverURL.absoluteString, createAuthorizationRecap()]
        )
    }

    public func register(params: IdentityRegistrationParams, signature: CacaoSignature) async throws {
        try await identityClient.register(params: params, signature: signature)
        notifyAccountProvider.setAccount(try params.account)
        try await subscriptionWatcher.start()
    }

    public func unregister(account: Account) async throws {
        try await identityClient.unregister(account: account)
        notifyWatcherAgreementKeysProvider.removeAgreement(account: account)
        try notifyStorage.clearDatabase(account: account)
        notifyAccountProvider.logout()
        subscriptionWatcher.stop()
    }

    public func setLogging(level: LoggingLevel) {
        logger.setLogging(level: level)
    }

    public func subscribe(appDomain: String, account: Account) async throws {
        try await notifySubscribeRequester.subscribe(appDomain: appDomain, account: account)
    }

    public func update(topic: String, scope: Set<String>) async throws {
        try await notifyUpdateRequester.update(topic: topic, scope: scope)
    }

    public func getActiveSubscriptions(account: Account) -> [NotifySubscription] {
        return notifyStorage.getSubscriptions(account: account)
    }

    public func getMessageHistory(topic: String) -> [NotifyMessageRecord] {
        notifyStorage.getMessages(topic: topic)
    }

    public func deleteSubscription(topic: String) async throws {
        try await notifyDeleteSubscriptionRequester.delete(topic: topic)
    }

    public func deleteNotifyMessage(id: String) {
        try? notifyStorage.deleteMessage(id: id)
    }

    public func register(deviceToken: Data, enableEncrypted: Bool = false) async throws {
        try await pushClient.register(deviceToken: deviceToken, enableEncrypted: enableEncrypted)
    }

    public func isIdentityRegistered(account: Account) -> Bool {
        return identityClient.isIdentityRegistered(account: account)
    }

    public func subscriptionsPublisher(account: Account) -> AnyPublisher<[NotifySubscription], Never> {
        return notifyStorage.subscriptionsPublisher(account: account)
    }

    public func messagesPublisher(topic: String) -> AnyPublisher<[NotifyMessageRecord], Never> {
        return notifyStorage.messagesPublisher(topic: topic)
    }

    public func fetchHistory(subscription: NotifySubscription, after: String?, limit: Int) async throws -> Bool {
        let messages = try await historyService.fetchHistory(
            account: subscription.account,
            topic: subscription.topic,
            appAuthenticationKey: subscription.appAuthenticationKey,
            host: subscription.metadata.url, 
            after: after, 
            limit: limit
        )

        let records = messages.map { message in
            return NotifyMessageRecord(topic: subscription.topic, message: message, publishedAt: message.sentAt)
        }

        try notifyStorage.setMessages(records)

        return messages.count == limit
    }

    /// returns notify recap for all apps
    private func createAuthorizationRecap() -> String {
        // {"att":{"https://notify.walletconnect.com":{"manage/all-apps-notifications":[{}]}}}
        "urn:recap:eyJhdHQiOnsiaHR0cHM6Ly9ub3RpZnkud2FsbGV0Y29ubmVjdC5jb20iOnsibWFuYWdlL2FsbC1hcHBzLW5vdGlmaWNhdGlvbnMiOlt7fV19fX0"
    }
}


#if targetEnvironment(simulator)
extension NotifyClient {

    public var subscriptionChangedPublisher: AnyPublisher<[NotifySubscription], Never> {
        return notifySubscriptionsUpdater.subscriptionChangedPublisher
    }

    public func register(deviceToken: String) async throws {
        try await pushClient.register(deviceToken: deviceToken)
    }
}
#endif

