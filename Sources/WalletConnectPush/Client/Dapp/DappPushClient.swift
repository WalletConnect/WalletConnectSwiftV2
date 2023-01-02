import Foundation
import Combine
import WalletConnectUtils

public class DappPushClient {

    private let responsePublisherSubject = PassthroughSubject<(id: RPCID, result: Result<PushSubscription, PushError>), Never>()

    public var responsePublisher: AnyPublisher<(id: RPCID, result: Result<PushSubscription, PushError>), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    private let deleteSubscriptionPublisherSubject = PassthroughSubject<String, Never>()

    public var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        deleteSubscriptionPublisherSubject.eraseToAnyPublisher()
    }

    public let logger: ConsoleLogging

    private let pushProposer: PushProposer
    private let pushMessageSender: PushMessageSender
    private let proposalResponseSubscriber: ProposalResponseSubscriber
    private let subscriptionsProvider: SubscriptionsProvider
    private let deletePushSubscriptionService: DeletePushSubscriptionService
    private let deletePushSubscriptionSubscriber: DeletePushSubscriptionSubscriber
    private let resubscribeService: PushResubscribeService

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         pushProposer: PushProposer,
         proposalResponseSubscriber: ProposalResponseSubscriber,
         pushMessageSender: PushMessageSender,
         subscriptionsProvider: SubscriptionsProvider,
         deletePushSubscriptionService: DeletePushSubscriptionService,
         deletePushSubscriptionSubscriber: DeletePushSubscriptionSubscriber,
         resubscribeService: PushResubscribeService) {
        self.logger = logger
        self.pushProposer = pushProposer
        self.proposalResponseSubscriber = proposalResponseSubscriber
        self.pushMessageSender = pushMessageSender
        self.subscriptionsProvider = subscriptionsProvider
        self.deletePushSubscriptionService = deletePushSubscriptionService
        self.deletePushSubscriptionSubscriber = deletePushSubscriptionSubscriber
        self.resubscribeService = resubscribeService
        setupSubscriptions()
    }

    public func request(account: Account, topic: String) async throws {
        try await pushProposer.request(topic: topic, account: account)
    }

    public func notify(topic: String, message: PushMessage) async throws {
        try await pushMessageSender.request(topic: topic, message: message)
    }

    public func getActiveSubscriptions() -> [PushSubscription] {
        subscriptionsProvider.getActiveSubscriptions()
    }

    public func delete(topic: String) async throws {
        try await deletePushSubscriptionService.delete(topic: topic)
    }

}

private extension DappPushClient {

    func setupSubscriptions() {
        proposalResponseSubscriber.onResponse = {[unowned self] (id, result) in
            responsePublisherSubject.send((id, result))
        }
        deletePushSubscriptionSubscriber.onDelete = {[unowned self] topic in
            deleteSubscriptionPublisherSubject.send(topic)
        }
    }
}
