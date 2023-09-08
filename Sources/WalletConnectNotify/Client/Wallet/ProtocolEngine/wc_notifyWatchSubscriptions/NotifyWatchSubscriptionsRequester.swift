import Foundation

class NotifyWatchSubscriptionsRequester {

    private let keyserverURL: URL
    private let identityClient: IdentityClient
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let webDidResolver: WebDidResolver
    private let notifyServerUrl = "https://dev.notify.walletconnect.com"

    init(keyserverURL: URL,
         networkingInteractor: NetworkInteracting,
         identityClient: IdentityClient,
         logger: ConsoleLogging,
         kms: KeyManagementService,
         webDidResolver: WebDidResolver
    ) {
        self.keyserverURL = keyserverURL
        self.identityClient = identityClient
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.webDidResolver = webDidResolver
    }

    func watchSubscriptions(account: Account) async throws {

        logger.debug("Watching subscriptions")

        let notifyServerAgreementKey = try await webDidResolver.resolveAgreementKey(domain: notifyServerUrl)
        let notifyServerAuthenticationKey = try await webDidResolver.resolveAuthenticationKey(domain: notifyServerUrl)
        let notifyServerAuthenticationDidKey = DIDKey(rawData: notifyServerAuthenticationKey)
        let watchSubscriptionsTopic = notifyServerAgreementKey.rawRepresentation.sha256().toHexString()

        // todo - generate keypair only once
        let keysY = try generateAgreementKeys(peerPublicKey: notifyServerAgreementKey)

        let responseTopic = keysY.derivedTopic()

        try kms.setSymmetricKey(keysY.sharedKey, for: watchSubscriptionsTopic)
        try kms.setAgreementSecret(keysY, topic: responseTopic)

        logger.debug("setting symm key for response topic \(responseTopic)")

        let protocolMethod = NotifyWatchSubscriptionsProtocolMethod()


        let watchSubscriptionsAuthWrapper = try await createJWTWrapper(
            notifyServerAuthenticationDidKey: notifyServerAuthenticationDidKey,
            subscriptionAccount: account)


        let request = RPCRequest(method: protocolMethod.method, params: watchSubscriptionsAuthWrapper)

        logger.debug("Subscribing to response topic: \(responseTopic)")

        try await networkingInteractor.subscribe(topic: responseTopic)

        try await networkingInteractor.request(request, topic: watchSubscriptionsTopic, protocolMethod: protocolMethod, envelopeType: .type1(pubKey: keysY.publicKey.rawRepresentation))
    }


    private func generateAgreementKeys(peerPublicKey: AgreementPublicKey) throws -> AgreementKeys {
        let selfPubKey = try kms.createX25519KeyPair()

        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPublicKey.hexRepresentation)
        return keys
    }

    private func createJWTWrapper(notifyServerAuthenticationDidKey: DIDKey, subscriptionAccount: Account) async throws -> NotifyWatchSubscriptionsPayload.Wrapper {
        let jwtPayload = NotifyWatchSubscriptionsPayload(notifyServerAuthenticationKey: notifyServerAuthenticationDidKey, keyserver: keyserverURL, subscriptionAccount: subscriptionAccount)
        return try identityClient.signAndCreateWrapper(
            payload: jwtPayload,
            account: subscriptionAccount
        )
    }
}
