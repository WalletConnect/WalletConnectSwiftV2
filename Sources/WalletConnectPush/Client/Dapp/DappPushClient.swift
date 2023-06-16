import Foundation
import Combine

public class DappPushClient {
    public var proposalResponsePublisher: AnyPublisher<Result<PushSubscription, PushError>, Never> {
        return notifyProposeResponseSubscriber.proposalResponsePublisher
    }

    public var deleteSubscriptionPublisher: AnyPublisher<String, Never> {
        deletePushSubscriptionSubscriber.deleteSubscriptionPublisher
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
    }

    public func propose(account: Account, topic: String) async throws {
        try await notifyProposer.propose(topic: topic, account: account)
    }

    public func getActiveSubscriptions() -> [PushSubscription] {
        subscriptionsProvider.getActiveSubscriptions()
    }
}
