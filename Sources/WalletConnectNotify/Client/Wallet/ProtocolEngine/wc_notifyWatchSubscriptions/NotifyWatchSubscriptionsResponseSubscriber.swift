import Foundation
import Combine

class NotifyWatchSubscriptionsResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage
    private let groupKeychainStorage: KeychainStorageProtocol
    private let notifySubscriptionsBuilder: NotifySubscriptionsBuilder

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging,
         notifyStorage: NotifyStorage,
         groupKeychainStorage: KeychainStorageProtocol,
         notifySubscriptionsBuilder: NotifySubscriptionsBuilder
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.notifyStorage = notifyStorage
        self.groupKeychainStorage = groupKeychainStorage
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

                let oldSubscriptions = notifyStorage.getSubscriptions()
                let newSubscriptions = try await notifySubscriptionsBuilder.buildSubscriptions(responsePayload.subscriptions)

                try Task.checkCancellation()

                logger.debug("number of subscriptions: \(newSubscriptions.count)")

                guard newSubscriptions != oldSubscriptions else {return}
                // todo: unsubscribe for oldSubscriptions topics that are not included in new subscriptions
                notifyStorage.replaceAllSubscriptions(newSubscriptions, account: account)
                
                for subscription in newSubscriptions {
                    let symKey = try SymmetricKey(hex: subscription.symKey)
                    try groupKeychainStorage.add(symKey, forKey: subscription.topic)
                    try kms.setSymmetricKey(symKey, for: subscription.topic)
                }

                try await networkingInteractor.batchSubscribe(topics: newSubscriptions.map { $0.topic })

                try Task.checkCancellation()

                var logProperties = [String: String]()
                for (index, subscription) in newSubscriptions.enumerated() {
                    let key = "subscription_\(index + 1)"
                    logProperties[key] = subscription.topic
                }

                logger.debug("Updated Subscriptions with Watch Subscriptions Update, number of subscriptions: \(newSubscriptions.count)", properties: logProperties)
            }
    }

}
