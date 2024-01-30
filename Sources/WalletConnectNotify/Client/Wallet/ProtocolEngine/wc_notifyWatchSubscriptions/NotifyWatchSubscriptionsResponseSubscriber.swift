import Foundation
import Combine

class NotifyWatchSubscriptionsResponseSubscriber {
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

        subscribeForWatchSubscriptionsResponse()
    }


    private func subscribeForWatchSubscriptionsResponse() {
        networkingInteractor.subscribeOnResponse(
            protocolMethod: NotifyWatchSubscriptionsProtocolMethod(),
            requestOfType: NotifyWatchSubscriptionsPayload.Wrapper.self,
            responseOfType: NotifyWatchSubscriptionsResponsePayload.Wrapper.self,
            errorHandler: logger) { [unowned self] payload in

                logger.debug("Received Notify Watch Subscriptions response")

                let (requestPayload, _) = try NotifyWatchSubscriptionsPayload.decodeAndVerify(from: payload.request)
                let (responsePayload, _) = try NotifyWatchSubscriptionsResponsePayload.decodeAndVerify(from: payload.response)

                let subscriptions = try await notifySubscriptionsBuilder.buildSubscriptions(responsePayload.subscriptions)

                try await notifySubscriptionsUpdater.update(subscriptions: subscriptions, for: requestPayload.subscriptionAccount)
            }
    }

}
