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
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<NotifyWatchSubscriptionsPayload.Wrapper, NotifyWatchSubscriptionsResponsePayload.Wrapper>) in
                Task(priority: .high) {
                    logger.debug("Received Notify Watch Subscriptions response")

                    guard
                        let (responsePayload, _) = try? NotifyWatchSubscriptionsResponsePayload.decodeAndVerify(from: payload.response)
                    else { fatalError() /* TODO: Handle error */ }

                    // todo varify signature with notify server diddoc authentication key

                    let subscriptions = responsePayload.subscriptions

                    notifyStorage.replaceAllSubscriptions(subscriptions)

                    var properties = [String: String]()
                    for (index, subscription) in subscriptions.enumerated() {
                        let key = "subscription_\(index + 1)"
                        properties[key] = subscription.topic
                    }

                    logger.debug("Updated Subscriptions by Watch Subscriptions Update", properties: properties)

                }
            }.store(in: &publishers)
    }
}
