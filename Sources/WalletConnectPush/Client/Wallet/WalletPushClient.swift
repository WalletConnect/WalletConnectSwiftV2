import Foundation
import Combine


public class WalletPushClient {

    private var publishers = Set<AnyCancellable>()

    private let deletePushSubscriptionSubscriber: DeletePushSubscriptionSubscriber

    public var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        deletePushSubscriptionSubscriber.deleteSubscriptionPublisher
    }

    /// publishes new subscriptions
    public var subscriptionPublisher: AnyPublisher<Result<PushSubscription, Error>, Never> {
        return pushSubscribeResponseSubscriber.subscriptionPublisher
    }

    public var subscriptionsPublisher: AnyPublisher<[PushSubscription], Never> {
        return pushSubscriptionsObserver.subscriptionsPublisher
    }

    private let pushSubscriptionsObserver: PushSubscriptionsObserver

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
    private let syncClient: SyncClient
    private let pushMessageSubscriber: PushMessageSubscriber
    private let subscriptionsProvider: SubscriptionsProvider
    private let pushMessagesDatabase: PushMessagesDatabase
    private let resubscribeService: PushResubscribeService
    private let pushSubscribeResponseSubscriber: PushSubscribeResponseSubscriber
    private let notifyUpdateRequester: NotifyUpdateRequester
    private let notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber
    private let notifyProposeResponder: NotifyProposeResponder
    private let notifyProposeSubscriber: NotifyProposeSubscriber

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         echoClient: EchoClient,
         syncClient: SyncClient,
         pushMessageSubscriber: PushMessageSubscriber,
         subscriptionsProvider: SubscriptionsProvider,
         pushMessagesDatabase: PushMessagesDatabase,
         deletePushSubscriptionService: DeletePushSubscriptionService,
         resubscribeService: PushResubscribeService,
         pushSubscriptionsObserver: PushSubscriptionsObserver,
         pushSubscribeRequester: PushSubscribeRequester,
         pushSubscribeResponseSubscriber: PushSubscribeResponseSubscriber,
         notifyUpdateRequester: NotifyUpdateRequester,
         notifyUpdateResponseSubscriber: NotifyUpdateResponseSubscriber,
         notifyProposeResponder: NotifyProposeResponder,
         notifyProposeSubscriber: NotifyProposeSubscriber
    ) {
        self.logger = logger
        self.echoClient = echoClient
        self.syncClient = syncClient
        self.pushMessageSubscriber = pushMessageSubscriber
        self.subscriptionsProvider = subscriptionsProvider
        self.pushMessagesDatabase = pushMessagesDatabase
        self.deletePushSubscriptionService = deletePushSubscriptionService
        self.resubscribeService = resubscribeService
        self.pushSubscriptionsObserver = pushSubscriptionsObserver
        self.pushSubscribeRequester = pushSubscribeRequester
        self.pushSubscribeResponseSubscriber = pushSubscribeResponseSubscriber
        self.notifyUpdateRequester = notifyUpdateRequester
        self.notifyUpdateResponseSubscriber = notifyUpdateResponseSubscriber
        self.notifyProposeResponder = notifyProposeResponder
        self.notifyProposeSubscriber = notifyProposeSubscriber
    }

    public func register(account: Account, onSign: @escaping SigningCallback) async throws {
        try await subscriptionsProvider.initialize(account: account)

        guard !syncClient.isRegistered(account: account) else { return }

        let result = await onSign(syncClient.getMessage(account: account))

        switch result {
        case .signed(let signature):
            try await syncClient.register(account: account, signature: signature)
            logger.debug("Sync pushSubscriptions store registered and initialized")
        case .rejected:
            throw PushError.registerSignatureRejected
        }
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
        subscriptionsProvider.getActiveSubscriptions()
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

