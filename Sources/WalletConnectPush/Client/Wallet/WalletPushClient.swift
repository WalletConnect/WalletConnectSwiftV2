import Foundation
import Combine

public class WalletPushClient {

    private var publishers = Set<AnyCancellable>()

    /// publishes new subscriptions
    public var newSubscriptionPublisher: AnyPublisher<PushSubscription, Never> {
        return pushStorage.newSubscriptionPublisher
    }

    public var subscriptionErrorPublisher: AnyPublisher<Error, Never> {
        return pushSubscribeResponseSubscriber.subscriptionErrorPublisher
    }

    public var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        return pushStorage.deleteSubscriptionPublisher
    }

    public var subscriptionsPublisher: AnyPublisher<[PushSubscription], Never> {
        return pushStorage.subscriptionsPublisher
    }

    public var requestPublisher: AnyPublisher<PushRequest, Never> {
        notifyProposeSubscriber.requestPublisher
    }

    public var pushMessagePublisher: AnyPublisher<PushMessageRecord, Never> {
        pushMessageSubscriber.pushMessagePublisher
    }

    public var updateSubscriptionPublisher: AnyPublisher<Result<PushSubscription, Error>, Never> {
        return notifyUpdateResponseSubscriber.updateSubscriptionPublisher
    }

    private let deletePushSubscriptionService: DeletePushSubscriptionService
    private let pushSubscribeRequester: PushSubscribeRequester

    public let logger: ConsoleLogging

    private let echoClient: EchoClient
    private let pushStorage: PushStorage
    private let pushSyncService: PushSyncService
    private let pushMessageSubscriber: PushMessageSubscriber
    private let pushMessagesDatabase: PushMessagesDatabase
    private let resubscribeService: PushResubscribeService
    private let pushSubscribeResponseSubscriber: PushSubscribeResponseSubscriber
    private let deletePushSubscriptionSubscriber: DeletePushSubscriptionSubscriber
    private let notifyUpdateRequester: NotifyUpdateRequester
    private let notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber
    private let notifyProposeResponder: NotifyProposeResponder
    private let notifyProposeSubscriber: NotifyProposeSubscriber
    private let subscriptionsAutoUpdater: SubscriptionsAutoUpdater

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         echoClient: EchoClient,
         pushMessageSubscriber: PushMessageSubscriber,
         pushStorage: PushStorage,
         pushSyncService: PushSyncService,
         pushMessagesDatabase: PushMessagesDatabase,
         deletePushSubscriptionService: DeletePushSubscriptionService,
         resubscribeService: PushResubscribeService,
         pushSubscribeRequester: PushSubscribeRequester,
         pushSubscribeResponseSubscriber: PushSubscribeResponseSubscriber,
         deletePushSubscriptionSubscriber: DeletePushSubscriptionSubscriber,
         notifyUpdateRequester: NotifyUpdateRequester,
         notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber,
         notifyProposeResponder: NotifyProposeResponder,
         notifyProposeSubscriber: NotifyProposeSubscriber,
         subscriptionsAutoUpdater: SubscriptionsAutoUpdater
    ) {
        self.logger = logger
        self.echoClient = echoClient
        self.pushMessageSubscriber = pushMessageSubscriber
        self.pushStorage = pushStorage
        self.pushSyncService = pushSyncService
        self.pushMessagesDatabase = pushMessagesDatabase
        self.deletePushSubscriptionService = deletePushSubscriptionService
        self.resubscribeService = resubscribeService
        self.pushSubscribeRequester = pushSubscribeRequester
        self.pushSubscribeResponseSubscriber = pushSubscribeResponseSubscriber
        self.deletePushSubscriptionSubscriber = deletePushSubscriptionSubscriber
        self.notifyUpdateRequester = notifyUpdateRequester
        self.notifyUpdateResponseSubscriber = notifyUpdateResponseSubscriber
        self.notifyProposeResponder = notifyProposeResponder
        self.notifyProposeSubscriber = notifyProposeSubscriber
        self.subscriptionsAutoUpdater = subscriptionsAutoUpdater
    }

    public func enableSync(account: Account, onSign: @escaping SigningCallback) async throws {
        try await pushStorage.setupSubscriptions(account: account)
        try await pushSyncService.registerIfNeeded(account: account, onSign: onSign)
        try await pushStorage.initialize(account: account)
    }

    public func subscribe(metadata: AppMetadata, account: Account, onSign: @escaping SigningCallback) async throws {
        try await pushSubscribeRequester.subscribe(metadata: metadata, account: account, onSign: onSign)
    }

    public func approve(id: RPCID, onSign: @escaping SigningCallback) async throws {
        try await notifyProposeResponder.approve(requestId: id, onSign: onSign)
    }

    public func reject(id: RPCID) async throws {
        try await notifyProposeResponder.reject(requestId: id)
    }

    public func update(topic: String, scope: Set<String>) async throws {
        try await notifyUpdateRequester.update(topic: topic, scope: scope)
    }

    public func getActiveSubscriptions() -> [PushSubscription] {
        return pushStorage.getSubscriptions()
    }

    public func getMessageHistory(topic: String) -> [PushMessageRecord] {
        pushMessagesDatabase.getPushMessages(topic: topic)
    }

    public func deleteSubscription(topic: String) async throws {
        try await deletePushSubscriptionService.delete(topic: topic)
    }

    public func deletePushMessage(id: String) {
        pushMessagesDatabase.deletePushMessage(id: id)
    }

    public func register(deviceToken: Data) async throws {
        try await echoClient.register(deviceToken: deviceToken)
    }
}

#if targetEnvironment(simulator)
extension WalletPushClient {
    public func register(deviceToken: String) async throws {
        try await echoClient.register(deviceToken: deviceToken)
    }
}
#endif

