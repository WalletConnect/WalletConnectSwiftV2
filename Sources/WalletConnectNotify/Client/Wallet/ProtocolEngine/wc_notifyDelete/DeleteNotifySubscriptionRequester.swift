import Foundation

class DeleteNotifySubscriptionRequester {
    enum Errors: Error {
        case notifySubscriptionNotFound
    }
    private let keyserver: URL
    private let networkingInteractor: NetworkInteracting
    private let identityClient: IdentityClient
    private let webDidResolver: NotifyWebDidResolver
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging
    private let notifyStorage: NotifyStorage

    init(
        keyserver: URL,
        networkingInteractor: NetworkInteracting,
        identityClient: IdentityClient,
        webDidResolver: NotifyWebDidResolver,
        kms: KeyManagementServiceProtocol,
        logger: ConsoleLogging,
        notifyStorage: NotifyStorage
    ) {
        self.keyserver = keyserver
        self.networkingInteractor = networkingInteractor
        self.identityClient = identityClient
        self.webDidResolver = webDidResolver
        self.kms = kms
        self.logger = logger
        self.notifyStorage = notifyStorage
    }

    func delete(topic: String) async throws {
        logger.debug("Will delete notify subscription")

        guard let subscription = notifyStorage.getSubscription(topic: topic)
        else { throw Errors.notifySubscriptionNotFound}

        let protocolMethod = NotifyDeleteProtocolMethod()
        let dappAuthenticationKey = try await webDidResolver.resolveAuthenticationKey(domain: subscription.metadata.url)

        let wrapper = try createJWTWrapper(
            dappPubKey: DIDKey(rawData: dappAuthenticationKey),
            reason: NotifyDeleteParams.userDisconnected.message,
            app: DIDWeb(host: subscription.metadata.url),
            account: subscription.account
        )

        let request = RPCRequest(method: protocolMethod.method, params: wrapper)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)

        try notifyStorage.deleteSubscription(topic: topic)
        notifyStorage.deleteMessages(topic: topic)

        networkingInteractor.unsubscribe(topic: topic)

        logger.debug("Subscription removed, topic: \(topic)")

        kms.deleteSymmetricKey(for: topic)
    }



    
}

private extension DeleteNotifySubscriptionRequester {

    func createJWTWrapper(dappPubKey: DIDKey, reason: String, app: DIDWeb, account: Account) throws -> NotifyDeletePayload.Wrapper {
        let jwtPayload = NotifyDeletePayload(account: account, keyserver: keyserver, dappPubKey: dappPubKey, app: app)
        return try identityClient.signAndCreateWrapper(
            payload: jwtPayload,
            account: account
        )
    }
}
