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

    private let deleteNotifySubscriptionRequester: DeleteNotifySubscriptionRequester
    private let notifySubscribeRequester: NotifySubscribeRequester

    public let logger: ConsoleLogging

    private let pushClient: PushClient
    private let identityService: NotifyIdentityService
    private let notifyStorage: NotifyStorage
    private let notifyAccountProvider: NotifyAccountProvider
    private let notifyMessageSubscriber: NotifyMessageSubscriber
    private let resubscribeService: NotifyResubscribeService
    private let notifySubscribeResponseSubscriber: NotifySubscribeResponseSubscriber
    private let notifyUpdateRequester: NotifyUpdateRequester
    private let notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber
    private let subscriptionsAutoUpdater: SubscriptionsAutoUpdater
    private let notifyWatchSubscriptionsResponseSubscriber: NotifyWatchSubscriptionsResponseSubscriber
    private let notifyWatcherAgreementKeysProvider: NotifyWatcherAgreementKeysProvider
    private let notifySubscriptionsChangedRequestSubscriber: NotifySubscriptionsChangedRequestSubscriber
    private let subscriptionWatcher: SubscriptionWatcher

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         identityService: NotifyIdentityService,
         pushClient: PushClient,
         notifyMessageSubscriber: NotifyMessageSubscriber,
         notifyStorage: NotifyStorage,
         deleteNotifySubscriptionRequester: DeleteNotifySubscriptionRequester,
         resubscribeService: NotifyResubscribeService,
         notifySubscribeRequester: NotifySubscribeRequester,
         notifySubscribeResponseSubscriber: NotifySubscribeResponseSubscriber,
         notifyUpdateRequester: NotifyUpdateRequester,
         notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber,
         notifyAccountProvider: NotifyAccountProvider,
         subscriptionsAutoUpdater: SubscriptionsAutoUpdater,
         notifyWatchSubscriptionsResponseSubscriber: NotifyWatchSubscriptionsResponseSubscriber,
         notifyWatcherAgreementKeysProvider: NotifyWatcherAgreementKeysProvider,
         notifySubscriptionsChangedRequestSubscriber: NotifySubscriptionsChangedRequestSubscriber,
         subscriptionWatcher: SubscriptionWatcher
    ) {
        self.logger = logger
        self.pushClient = pushClient
        self.identityService = identityService
        self.notifyMessageSubscriber = notifyMessageSubscriber
        self.notifyStorage = notifyStorage
        self.deleteNotifySubscriptionRequester = deleteNotifySubscriptionRequester
        self.resubscribeService = resubscribeService
        self.notifySubscribeRequester = notifySubscribeRequester
        self.notifySubscribeResponseSubscriber = notifySubscribeResponseSubscriber
        self.notifyUpdateRequester = notifyUpdateRequester
        self.notifyUpdateResponseSubscriber = notifyUpdateResponseSubscriber
        self.notifyAccountProvider = notifyAccountProvider
        self.subscriptionsAutoUpdater = subscriptionsAutoUpdater
        self.notifyWatchSubscriptionsResponseSubscriber = notifyWatchSubscriptionsResponseSubscriber
        self.notifyWatcherAgreementKeysProvider = notifyWatcherAgreementKeysProvider
        self.notifySubscriptionsChangedRequestSubscriber = notifySubscriptionsChangedRequestSubscriber
        self.subscriptionWatcher = subscriptionWatcher
    }

    public func register(account: Account, domain: String, isLimited: Bool = false, onSign: @escaping SigningCallback) async throws {
        try await identityService.register(account: account, domain: domain, isLimited: isLimited, onSign: onSign)
        notifyAccountProvider.setAccount(account)
        try await subscriptionWatcher.start()
    }

    public func unregister(account: Account) async throws {
        try await identityService.unregister(account: account)
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
        try await deleteNotifySubscriptionRequester.delete(topic: topic)
    }

    public func deleteNotifyMessage(id: String) {
        try? notifyStorage.deleteMessage(id: id)
    }

    public func register(deviceToken: Data) async throws {
        try await pushClient.register(deviceToken: deviceToken)
    }

    public func isIdentityRegistered(account: Account) -> Bool {
        return identityService.isIdentityRegistered(account: account)
    }

    public func subscriptionsPublisher(account: Account) -> AnyPublisher<[NotifySubscription], Never> {
        return notifyStorage.subscriptionsPublisher(account: account)
    }

    public func messagesPublisher(topic: String) -> AnyPublisher<[NotifyMessageRecord], Never> {
        return notifyStorage.messagesPublisher(topic: topic)
    }
}

#if targetEnvironment(simulator)
extension NotifyClient {

    public var subscriptionChangedPublisher: AnyPublisher<[NotifySubscription], Never> {
        return notifySubscriptionsChangedRequestSubscriber.subscriptionChangedPublisher
    }

    public func register(deviceToken: String) async throws {
        try await pushClient.register(deviceToken: deviceToken)
    }
}
#endif

