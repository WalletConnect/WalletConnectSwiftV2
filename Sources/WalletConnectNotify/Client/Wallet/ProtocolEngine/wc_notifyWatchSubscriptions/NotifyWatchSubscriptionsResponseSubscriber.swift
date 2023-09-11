import Foundation
import Combine

class NotifyWatchSubscriptionsResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage
    private let notifySubscriptionsBuilder: NotifySubscriptionsBuilder

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         notifyStorage: NotifyStorage,
         notifySubscriptionsBuilder: NotifySubscriptionsBuilder
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.notifyStorage = notifyStorage
        self.notifySubscriptionsBuilder = notifySubscriptionsBuilder
        subscribeForWatchSubscriptionsResponse()
    }


    private func subscribeForWatchSubscriptionsResponse() {
        networkingInteractor.subscribeOnResponse(
            protocolMethod: NotifyWatchSubscriptionsProtocolMethod(),
            requestOfType: NotifyWatchSubscriptionsPayload.Wrapper.self,
            responseOfType: NotifyWatchSubscriptionsResponsePayload.Wrapper.self,
            errorHandler: logger) { [unowned self] payload in
                logger.debug("Received Notify Watch Subscriptions response")

                let (responsePayload, _) = try NotifyWatchSubscriptionsResponsePayload.decodeAndVerify(from: payload.response)
                let (watchSubscriptionPayloadRequest, _) = try NotifyWatchSubscriptionsPayload.decodeAndVerify(from: payload.request)

                let account = watchSubscriptionPayloadRequest.subscriptionAccount
                // todo varify signature with notify server diddoc authentication key

                let subscriptions = try await notifySubscriptionsBuilder.buildSubscriptions(responsePayload.subscriptions)

                notifyStorage.replaceAllSubscriptions(subscriptions, account: account)

                var logProperties = [String: String]()
                for (index, subscription) in subscriptions.enumerated() {
                    let key = "subscription_\(index + 1)"
                    logProperties[key] = subscription.topic
                }

                logger.debug("Updated Subscriptions with Watch Subscriptions Update, number of subscriptions: \(subscriptions.count)", properties: logProperties)
            }
    }

}
