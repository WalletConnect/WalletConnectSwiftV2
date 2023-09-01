import Foundation
import Combine

public class NotifyClient {

    private var publishers = Set<AnyCancellable>()

    /// publishes new subscriptions
    public var newSubscriptionPublisher: AnyPublisher<NotifySubscription, Never> {
        return notifyStorage.newSubscriptionPublisher
    }

    public var subscriptionErrorPublisher: AnyPublisher<Error, Never> {
        return notifySubscribeResponseSubscriber.subscriptionErrorPublisher
    }

    public var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        return notifyStorage.deleteSubscriptionPublisher
    }

    public var subscriptionsPublisher: AnyPublisher<[NotifySubscription], Never> {
        return notifyStorage.subscriptionsPublisher
    }

    public var notifyMessagePublisher: AnyPublisher<NotifyMessageRecord, Never> {
        return notifyMessageSubscriber.notifyMessagePublisher
    }

    public var updateSubscriptionPublisher: AnyPublisher<NotifySubscription, Never> {
        return notifyStorage.updateSubscriptionPublisher
    }

    private let deleteNotifySubscriptionService: DeleteNotifySubscriptionService
    private let notifySubscribeRequester: NotifySubscribeRequester

    public let logger: ConsoleLogging

    private let pushClient: PushClient
    private let identityClient: IdentityClient
    private let notifyStorage: NotifyStorage
    private let notifyMessageSubscriber: NotifyMessageSubscriber
    private let resubscribeService: NotifyResubscribeService
    private let notifySubscribeResponseSubscriber: NotifySubscribeResponseSubscriber
    private let deleteNotifySubscriptionSubscriber: DeleteNotifySubscriptionSubscriber
    private let notifyUpdateRequester: NotifyUpdateRequester
    private let notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber
    private let subscriptionsAutoUpdater: SubscriptionsAutoUpdater

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         identityClient: IdentityClient,
         pushClient: PushClient,
         notifyMessageSubscriber: NotifyMessageSubscriber,
         notifyStorage: NotifyStorage,
         deleteNotifySubscriptionService: DeleteNotifySubscriptionService,
         resubscribeService: NotifyResubscribeService,
         notifySubscribeRequester: NotifySubscribeRequester,
         notifySubscribeResponseSubscriber: NotifySubscribeResponseSubscriber,
         deleteNotifySubscriptionSubscriber: DeleteNotifySubscriptionSubscriber,
         notifyUpdateRequester: NotifyUpdateRequester,
         notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber,
         subscriptionsAutoUpdater: SubscriptionsAutoUpdater
    ) {
        self.logger = logger
        self.pushClient = pushClient
        self.identityClient = identityClient
        self.notifyMessageSubscriber = notifyMessageSubscriber
        self.notifyStorage = notifyStorage
        self.deleteNotifySubscriptionService = deleteNotifySubscriptionService
        self.resubscribeService = resubscribeService
        self.notifySubscribeRequester = notifySubscribeRequester
        self.notifySubscribeResponseSubscriber = notifySubscribeResponseSubscriber
        self.deleteNotifySubscriptionSubscriber = deleteNotifySubscriptionSubscriber
        self.notifyUpdateRequester = notifyUpdateRequester
        self.notifyUpdateResponseSubscriber = notifyUpdateResponseSubscriber
        self.subscriptionsAutoUpdater = subscriptionsAutoUpdater
    }

    public func register(account: Account, onSign: @escaping SigningCallback) async throws {
        _ = try await identityClient.register(account: account, onSign: onSign)
    }

    public func subscribe(metadata: AppMetadata, account: Account, onSign: @escaping SigningCallback) async throws {
        try await notifySubscribeRequester.subscribe(metadata: metadata, account: account, onSign: onSign)
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
        try await deleteNotifySubscriptionService.delete(topic: topic)
    }

    public func deleteNotifyMessage(id: String) {
        notifyStorage.deleteMessage(id: id)
    }

    public func register(deviceToken: Data) async throws {
        try await pushClient.register(deviceToken: deviceToken)
    }

    public func isIdentityRegistered(account: Account) -> Bool {
        return identityClient.isIdentityRegistered(account: account)
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

