import Foundation
import Combine

public class NotifyClient {

    private var publishers = Set<AnyCancellable>()

    public var subscriptionsPublisher: AnyPublisher<[NotifySubscription], Never> {
        return notifyStorage.subscriptionsPublisher
    }

    public var notifyMessagePublisher: AnyPublisher<NotifyMessageRecord, Never> {
        return notifyMessageSubscriber.notifyMessagePublisher
    }

    public var logsPublisher: AnyPublisher<Log, Never> {
        logger.logsPublisher
            .eraseToAnyPublisher()
    }

    private let deleteNotifySubscriptionRequester: DeleteNotifySubscriptionRequester
    private let notifySubscribeRequester: NotifySubscribeRequester

    public let logger: ConsoleLogging

    private let pushClient: PushClient
    private let identityService: NotifyIdentityService
    private let notifyStorage: NotifyStorage
    private let notifyMessageSubscriber: NotifyMessageSubscriber
    private let resubscribeService: NotifyResubscribeService
    private let notifySubscribeResponseSubscriber: NotifySubscribeResponseSubscriber
    private let notifyUpdateRequester: NotifyUpdateRequester
    private let notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber
    private let subscriptionsAutoUpdater: SubscriptionsAutoUpdater
    private let notifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequester
    private let notifyWatchSubscriptionsResponseSubscriber: NotifyWatchSubscriptionsResponseSubscriber
    private let notifySubscriptionsChangedRequestSubscriber: NotifySubscriptionsChangedRequestSubscriber

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
         subscriptionsAutoUpdater: SubscriptionsAutoUpdater,
         notifyWatchSubscriptionsRequester: NotifyWatchSubscriptionsRequester,
         notifyWatchSubscriptionsResponseSubscriber: NotifyWatchSubscriptionsResponseSubscriber,
         notifySubscriptionsChangedRequestSubscriber: NotifySubscriptionsChangedRequestSubscriber
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
        self.subscriptionsAutoUpdater = subscriptionsAutoUpdater
        self.notifyWatchSubscriptionsRequester = notifyWatchSubscriptionsRequester
        self.notifyWatchSubscriptionsResponseSubscriber = notifyWatchSubscriptionsResponseSubscriber
        self.notifySubscriptionsChangedRequestSubscriber = notifySubscriptionsChangedRequestSubscriber
    }

    public func register(account: Account, domain: String, isLimited: Bool = false, onSign: @escaping SigningCallback) async throws {
        try await identityService.register(account: account, domain: domain, isLimited: isLimited, onSign: onSign)
        notifyWatchSubscriptionsRequester.setAccount(account)
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

    public func getActiveSubscriptions() -> [NotifySubscription] {
        return notifyStorage.getSubscriptions()
    }

    public func getMessageHistory(topic: String) -> [NotifyMessageRecord] {
        notifyStorage.getMessages(topic: topic)
    }

    public func deleteSubscription(topic: String) async throws {
        try await deleteNotifySubscriptionRequester.delete(topic: topic)
    }

    public func deleteNotifyMessage(id: String) {
        notifyStorage.deleteMessage(id: id)
    }

    public func register(deviceToken: Data) async throws {
        try await pushClient.register(deviceToken: deviceToken)
    }

    public func isIdentityRegistered(account: Account) -> Bool {
        return identityService.isIdentityRegistered(account: account)
    }

    public func messagesPublisher(topic: String) -> AnyPublisher<[NotifyMessageRecord], Never> {
        return notifyStorage.messagesPublisher(topic: topic)
    }
}

#if targetEnvironment(simulator)
extension NotifyClient {
    public func register(deviceToken: String) async throws {
        try await pushClient.register(deviceToken: deviceToken)
    }
}
#endif

