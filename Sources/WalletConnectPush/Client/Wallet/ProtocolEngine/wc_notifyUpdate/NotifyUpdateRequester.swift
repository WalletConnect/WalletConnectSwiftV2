
import Foundation

class NotifyUpdateRequester {
    enum Errors: Error {
        case noSubscriptionForGivenTopic
    }

    private let keyserverURL: URL
    private let identityClient: IdentityClient
    private let networkingInteractor: NetworkInteracting
    private let logger: ConsoleLogging
    private let subscriptionsStore: CodableStore<PushSubscription>

    init(keyserverURL: URL,
         identityClient: IdentityClient,
         networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         subscriptionsStore: CodableStore<PushSubscription>
    ) {
        self.keyserverURL = keyserverURL
        self.identityClient = identityClient
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.subscriptionsStore = subscriptionsStore
    }

    func update(topic: String, scope: Set<String>) async throws {

        logger.debug("NotifyUpdateRequester: updating subscription for topic: \(topic)")
        guard let subscription = try subscriptionsStore.get(key: topic) else { throw Errors.noSubscriptionForGivenTopic }

        let request = try createJWTRequest(subscriptionAccount: subscription.account, dappUrl: subscription.metadata.url, scope: scope)

        let protocolMethod = NotifyUpdateProtocolMethod()

        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
    }

    private func createJWTRequest(subscriptionAccount: Account, dappUrl: String, scope: Set<String>) throws -> RPCRequest {
        let protocolMethod = NotifyUpdateProtocolMethod().method
        let scopeClaim = scope.joined(separator: " ")
        let jwtPayload = SubscriptionJWTPayload(keyserver: keyserverURL, subscriptionAccount: subscriptionAccount, dappUrl: dappUrl, scope: scopeClaim)
        let wrapper = try identityClient.signAndCreateWrapper(
            payload: jwtPayload,
            account: subscriptionAccount
        )
        print(wrapper.subscriptionAuth)
        return RPCRequest(method: protocolMethod, params: wrapper)
    }
}
