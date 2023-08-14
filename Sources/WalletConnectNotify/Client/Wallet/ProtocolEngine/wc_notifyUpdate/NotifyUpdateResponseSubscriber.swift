import Foundation
import Combine

class NotifyUpdateResponseSubscriber {
    private let networkingInteractor: NetworkInteracting
    private var publishers = [AnyCancellable]()
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage
    private let subscriptionScopeProvider: SubscriptionScopeProvider
    private var subscriptionPublisherSubject = PassthroughSubject<Result<NotifySubscription, Error>, Never>()
    var updateSubscriptionPublisher: AnyPublisher<Result<NotifySubscription, Error>, Never> {
        return subscriptionPublisherSubject.eraseToAnyPublisher()
    }

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
        let protocolMethod = NotifyUpdateProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink {[unowned self] (payload: ResponseSubscriptionPayload<NotifyUpdatePayload.Wrapper, NotifyUpdateResponsePayload.Wrapper>) in
                Task(priority: .high) {
                    logger.debug("Received Notify Update response")

                    let subscriptionTopic = payload.topic

                    let (requestPayload, requestClaims) = try NotifyUpdatePayload.decodeAndVerify(from: payload.request)
                    let (_, _) = try NotifyUpdateResponsePayload.decodeAndVerify(from: payload.response)

                    let scope = try await buildScope(selected: requestPayload.scope, dappUrl: requestPayload.dappUrl)

                    guard let oldSubscription = notifyStorage.getSubscription(topic: subscriptionTopic) else {
                        logger.debug("NotifyUpdateResponseSubscriber Subscription does not exist")
                        subscriptionPublisherSubject.send(.failure(Errors.subscriptionDoesNotExist))
                        return
                    }
                    let expiry = Date(timeIntervalSince1970: TimeInterval(requestClaims.exp))

                    let updatedSubscription = NotifySubscription(topic: subscriptionTopic, account: oldSubscription.account, relay: oldSubscription.relay, metadata: oldSubscription.metadata, scope: scope, expiry: expiry, symKey: oldSubscription.symKey)

                    try await notifyStorage.setSubscription(updatedSubscription)

                    subscriptionPublisherSubject.send(.success(updatedSubscription))

                    logger.debug("Updated Subscription")
                }
            }.store(in: &publishers)
    }

    func buildScope(selected: String, dappUrl: String) async throws -> [String: ScopeValue] {
        let selectedScope = selected.components(separatedBy: " ")
        let availableScope = try await subscriptionScopeProvider.getSubscriptionScope(dappUrl: dappUrl)
        return availableScope.reduce(into: [:]) {
            $0[$1.name] = ScopeValue(description: $1.description, enabled: selectedScope.contains($1.name))
        }
    }
}
