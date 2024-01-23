import Foundation
import Combine

class NotifyUpdateResponseSubscriber {
    
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let notifySubscriptionsBuilder: NotifySubscriptionsBuilder
    private let notifySubscriptionsUpdater: NotifySubsctiptionsUpdater

    init(
        networkingInteractor: NetworkInteracting,
        logger: ConsoleLogging,
        notifySubscriptionsBuilder: NotifySubscriptionsBuilder,
        notifySubscriptionsUpdater: NotifySubsctiptionsUpdater
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.notifySubscriptionsBuilder = notifySubscriptionsBuilder
        self.notifySubscriptionsUpdater = notifySubscriptionsUpdater

        subscribeForUpdateResponse()
    }

    // TODO: handle error response
}

private extension NotifyUpdateResponseSubscriber {

    func subscribeForUpdateResponse() {
        networkingInteractor.subscribeOnResponse(
            protocolMethod: NotifyUpdateProtocolMethod(),
            requestOfType: NotifyUpdatePayload.Wrapper.self,
            responseOfType: NotifyUpdateResponsePayload.Wrapper.self,
            errorHandler: logger
        ) { [unowned self] payload in

            let (responsePayload, _) = try NotifyUpdateResponsePayload.decodeAndVerify(from: payload.response)

            let subscriptions = try await notifySubscriptionsBuilder.buildSubscriptions(responsePayload.subscriptions)

            try await notifySubscriptionsUpdater.update(subscriptions: subscriptions, for: responsePayload.account)

            logger.debug("Received Notify Update response")
        }
    }
}
