import Foundation
import Combine

class NotifyWatchSubscriptionsResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage
    private let subscriptionScopeProvider: SubscriptionScopeProvider

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         notifyStorage: NotifyStorage,
         subscriptionScopeProvider: SubscriptionScopeProvider
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.notifyStorage = notifyStorage
        self.subscriptionScopeProvider = subscriptionScopeProvider
        subscribeForWatchSubscriptionsResponse()
    }


    private func subscribeForWatchSubscriptionsResponse() {

        let protocolMethod = NotifySubscribeProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<NotifyWatchSubscriptionsPayload.Wrapper, NotifySubscriptionResponsePayload.Wrapper>) in
                Task(priority: .high) {
                    logger.debug("Received Notify watch Subscription response")


                }
            }.store(in: &publishers)
    }
}
