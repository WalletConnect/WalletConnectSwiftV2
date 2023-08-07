
import Foundation
import Combine

class NotifyUpdateResponseSubscriber {
    enum Errors: Error {
        case subscriptionDoesNotExist
    }

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

    private func subscribeForUpdateResponse() {
        let protocolMethod = NotifyUpdateProtocolMethod()
        networkingInteractor.responseSubscription(on: protocolMethod)
            .sink {[unowned self] (payload: ResponseSubscriptionPayload<NotifySubscriptionPayload.Wrapper, Bool>) in
                Task(priority: .high) {
                    logger.debug("Received Notify Update response")

                    let subscriptionTopic = payload.topic

                    let (_, claims) = try NotifySubscriptionPayload.decodeAndVerify(from: payload.request)
                    let scope = try await buildScope(selected: claims.scp, dappUrl: claims.aud)

                    guard let oldSubscription = notifyStorage.getSubscription(topic: subscriptionTopic) else {
                        logger.debug("NotifyUpdateResponseSubscriber Subscription does not exist")
                        subscriptionPublisherSubject.send(.failure(Errors.subscriptionDoesNotExist))
                        return
                    }
                    let expiry = Date(timeIntervalSince1970: TimeInterval(claims.exp))
                    
                    let updatedSubscription = NotifySubscription(topic: subscriptionTopic, account: oldSubscription.account, relay: oldSubscription.relay, metadata: oldSubscription.metadata, scope: scope, expiry: expiry, symKey: oldSubscription.symKey)

                    try await notifyStorage.setSubscription(updatedSubscription)

                    subscriptionPublisherSubject.send(.success(updatedSubscription))

                    logger.debug("Updated Subscription")
                }
            }.store(in: &publishers)
    }

    private func buildScope(selected: String, dappUrl: String) async throws -> [String: ScopeValue] {
        let selectedScope = selected
            .components(separatedBy: " ")

        let availableScope = try await subscriptionScopeProvider.getSubscriptionScope(dappUrl: dappUrl)
        return availableScope.reduce(into: [:]) { $0[$1.name] = ScopeValue(description: $1.description, enabled: selectedScope.contains($1.name)) }
    }

    // TODO: handle error response
}
