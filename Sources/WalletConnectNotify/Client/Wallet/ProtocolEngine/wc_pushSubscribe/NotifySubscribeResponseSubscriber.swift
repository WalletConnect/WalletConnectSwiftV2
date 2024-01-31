import Foundation
import Combine

class NotifySubscribeResponseSubscriber {

    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let notifySubscriptionsBuilder: NotifySubscriptionsBuilder
    private let notifySubscriptionsUpdater: NotifySubsctiptionsUpdater

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         notifySubscriptionsBuilder: NotifySubscriptionsBuilder,
         notifySubscriptionsUpdater: NotifySubsctiptionsUpdater
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.notifySubscriptionsBuilder = notifySubscriptionsBuilder
        self.notifySubscriptionsUpdater = notifySubscriptionsUpdater

        subscribeForSubscriptionResponse()
    }

    private func subscribeForSubscriptionResponse() {
        networkingInteractor.subscribeOnResponse(
            protocolMethod: NotifySubscribeProtocolMethod(),
            requestOfType: NotifySubscriptionPayload.Wrapper.self,
            responseOfType: NotifySubscriptionResponsePayload.Wrapper.self,
            errorHandler: logger
        ) { [unowned self] payload in
            logger.debug("Received Notify Subscribe response")

            let (requestPayload, _) = try NotifySubscriptionPayload.decodeAndVerify(from: payload.request)
            let (responsePayload, _) = try NotifySubscriptionResponsePayload.decodeAndVerify(from: payload.response)

            let subscriptions = try await notifySubscriptionsBuilder.buildSubscriptions(responsePayload.subscriptions)

            try await notifySubscriptionsUpdater.update(subscriptions: subscriptions, for: requestPayload.subscriptionAccount)

            logger.debug("NotifySubscribeResponseSubscriber: unsubscribing from response topic: \(payload.topic)")

            networkingInteractor.unsubscribe(topic: payload.topic)
        }
    }
}
