import Foundation

protocol NotifyUpdateRequesting {
    func update(topic: String, scope: Set<String>) async throws
}

class NotifyUpdateRequester: NotifyUpdateRequesting {
    enum Errors: Error {
        case noSubscriptionForGivenTopic
    }

    private let keyserverURL: URL
    private let webDidResolver: NotifyWebDidResolver
    private let identityClient: IdentityClient
    private let networkingInteractor: NetworkInteracting
    private let notifyConfigProvider: NotifyConfigProvider
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage

    init(
        keyserverURL: URL,
        webDidResolver: NotifyWebDidResolver,
        identityClient: IdentityClient,
        networkingInteractor: NetworkInteracting,
        notifyConfigProvider: NotifyConfigProvider,
        logger: ConsoleLogging,
        notifyStorage: NotifyStorage
    ) {
        self.keyserverURL = keyserverURL
        self.webDidResolver = webDidResolver
        self.identityClient = identityClient
        self.networkingInteractor = networkingInteractor
        self.notifyConfigProvider = notifyConfigProvider
        self.logger = logger
        self.notifyStorage = notifyStorage
    }

    func update(topic: String, scope: Set<String>) async throws {
        logger.debug("NotifyUpdateRequester: updating subscription for topic: \(topic)")

        guard let subscription = notifyStorage.getSubscription(topic: topic) else { throw Errors.noSubscriptionForGivenTopic }

        let dappAuthenticationKey = try await webDidResolver.resolveAuthenticationKey(domain: subscription.metadata.url)

        let request = try createJWTRequest(
            dappPubKey: DIDKey(rawData: dappAuthenticationKey),
            subscriptionAccount: subscription.account,
            appDomain: subscription.metadata.url, scope: scope,
            topic: topic
        )

        let protocolMethod = NotifyUpdateProtocolMethod()

        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
    }

    private func createJWTRequest(dappPubKey: DIDKey, subscriptionAccount: Account, appDomain: String, scope: Set<String>, topic: String) throws -> RPCRequest {
        let protocolMethod = NotifyUpdateProtocolMethod().method
        let scopeClaim = scope.joined(separator: " ")
        let app = DIDWeb(host: appDomain)
        let jwtPayload = NotifyUpdatePayload(dappPubKey: dappPubKey, keyserver: keyserverURL, subscriptionAccount: subscriptionAccount, app: app, scope: scopeClaim)
        let wrapper = try identityClient.signAndCreateWrapper(
            payload: jwtPayload,
            account: subscriptionAccount
        )
        return RPCRequest(method: protocolMethod, params: wrapper, topic: topic)
    }
}
