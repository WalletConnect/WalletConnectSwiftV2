import Foundation
import Combine

class NotifyDeleteSubscriptionSubscriber {

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let notifySubscriptionsBuilder: NotifySubscriptionsBuilder
    private let notifySubscriptionsUpdater: NotifySubsctiptionsUpdater

    init(
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        logger: ConsoleLogging,
        notifySubscriptionsBuilder: NotifySubscriptionsBuilder,
        notifySubscriptionsUpdater: NotifySubsctiptionsUpdater
    ) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
        self.notifySubscriptionsBuilder = notifySubscriptionsBuilder
        self.notifySubscriptionsUpdater = notifySubscriptionsUpdater

        subscribeForDeleteResponse()
    }
}

private extension NotifyDeleteSubscriptionSubscriber {

    func subscribeForDeleteResponse() {
        networkingInteractor.subscribeOnResponse(
            protocolMethod: NotifyDeleteProtocolMethod(),
            requestOfType: NotifyDeletePayload.Wrapper.self,
            responseOfType: NotifyDeleteResponsePayload.Wrapper.self,
            errorHandler: logger
        ) { [unowned self] payload in

            let (responsePayload, _) = try NotifyDeleteResponsePayload.decodeAndVerify(from: payload.response)

            let subscriptions = try await notifySubscriptionsBuilder.buildSubscriptions(responsePayload.subscriptions)

            try await notifySubscriptionsUpdater.update(subscriptions: subscriptions, for: responsePayload.account)

            logger.debug("Received Notify Delete response")

            networkingInteractor.unsubscribe(topic: payload.topic)
            kms.deleteSymmetricKey(for: payload.topic)
        }
    }
}
