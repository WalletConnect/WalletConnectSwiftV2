import Foundation
import Combine

class NotifyUpdateResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage
    private let subscriptionScopeProvider: SubscriptionScopeProvider

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         subscriptionScopeProvider: SubscriptionScopeProvider,
         notifyStorage: NotifyStorage
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.notifyStorage = notifyStorage
        self.subscriptionScopeProvider = subscriptionScopeProvider
        subscribeForUpdateResponse()
    }

    // TODO: handle error response
}

private extension NotifyUpdateResponseSubscriber {
    enum Errors: Error {
        case subscriptionDoesNotExist
        case selectedScopeNotFound
    }

    func subscribeForUpdateResponse() {
        networkingInteractor.subscribeOnResponse(
            protocolMethod: NotifyUpdateProtocolMethod(),
            requestOfType: NotifyUpdatePayload.Wrapper.self,
            responseOfType: NotifyUpdateResponsePayload.Wrapper.self,
            errorHandler: logger
        ) { [unowned self] payload in
            logger.debug("Received Notify Update response")

            let subscriptionTopic = payload.topic

            let (requestPayload, requestClaims) = try NotifyUpdatePayload.decodeAndVerify(from: payload.request)
            let (_, _) = try NotifyUpdateResponsePayload.decodeAndVerify(from: payload.response)

            let scope = try await buildScope(selected: requestPayload.scope, dappUrl: requestPayload.dappUrl)

            guard let oldSubscription = notifyStorage.getSubscription(topic: subscriptionTopic) else {
                logger.debug("NotifyUpdateResponseSubscriber Subscription does not exist")
                return
            }

            notifyStorage.updateSubscription(oldSubscription, scope: scope, expiry: requestClaims.exp)

            logger.debug("Updated Subscription")
        }
    }

    func buildScope(selected: String, dappUrl: String) async throws -> [String: ScopeValue] {
        let selectedScope = selected.components(separatedBy: " ")
        let availableScope = try await subscriptionScopeProvider.getSubscriptionScope(dappUrl: dappUrl)
        return availableScope.reduce(into: [:]) {
            $0[$1.name] = ScopeValue(description: $1.description, enabled: selectedScope.contains($1.name))
        }
    }
}
