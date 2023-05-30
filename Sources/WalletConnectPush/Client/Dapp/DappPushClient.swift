import Foundation
import Combine
import WalletConnectUtils

public class DappPushClient {
    public var proposalResponsePublisher: AnyPublisher<Result<PushSubscription, PushError>, Never> {
        return notifyProposeResponseSubscriber.proposalResponsePublisher
    }

    private let deleteSubscriptionPublisherSubject = PassthroughSubject<String, Never>()

    public var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        deleteSubscriptionPublisherSubject.eraseToAnyPublisher()
    }

    public let logger: ConsoleLogging

    private let notifyProposer: NotifyProposer
    private let subscriptionsProvider: SubscriptionsProvider
    private let deletePushSubscriptionSubscriber: DeletePushSubscriptionSubscriber
    private let resubscribeService: PushResubscribeService
    private let notifyProposeResponseSubscriber: NotifyProposeResponseSubscriber

    init(logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         subscriptionsProvider: SubscriptionsProvider,
         deletePushSubscriptionSubscriber: DeletePushSubscriptionSubscriber,
         resubscribeService: PushResubscribeService,
         notifyProposer: NotifyProposer,
         notifyProposeResponseSubscriber: NotifyProposeResponseSubscriber) {
        self.logger = logger
        self.subscriptionsProvider = subscriptionsProvider
        self.deletePushSubscriptionSubscriber = deletePushSubscriptionSubscriber
        self.resubscribeService = resubscribeService
        self.notifyProposer = notifyProposer
        self.notifyProposeResponseSubscriber = notifyProposeResponseSubscriber
        setupSubscriptions()
    }

    public func propose(account: Account, topic: String) async throws {
        try await notifyProposer.propose(topic: topic, account: account)
    }

    public func getActiveSubscriptions() -> [PushSubscription] {
        subscriptionsProvider.getActiveSubscriptions()
    }
}

private extension DappPushClient {

    func setupSubscriptions() {
        deletePushSubscriptionSubscriber.onDelete = {[unowned self] topic in
            deleteSubscriptionPublisherSubject.send(topic)
        }
    }
}
