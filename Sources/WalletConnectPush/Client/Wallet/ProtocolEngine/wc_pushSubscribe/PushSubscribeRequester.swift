
import Foundation

class PushSubscribeRequester {

    enum Errors: Error {
        case didDocDoesNotContainKeyAgreement
        case noVerificationMethodForKey
        case unsupportedCurve
    }

    private let keyserverURL: URL
    private let identityClient: IdentityClient
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let webDidResolver: WebDidResolver
    private let dappsMetadataStore: CodableStore<AppMetadata>
    private let subscriptionScopeProvider: SubscriptionScopeProvider

    init(keyserverURL: URL,
         networkingInteractor: NetworkInteracting,
         identityClient: IdentityClient,
         logger: ConsoleLogging,
         kms: KeyManagementService,
         webDidResolver: WebDidResolver = WebDidResolver(),
         subscriptionScopeProvider: SubscriptionScopeProvider,
         dappsMetadataStore: CodableStore<AppMetadata>
    ) {
        self.keyserverURL = keyserverURL
        self.identityClient = identityClient
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.webDidResolver = webDidResolver
        self.subscriptionScopeProvider = subscriptionScopeProvider
        self.dappsMetadataStore = dappsMetadataStore
    }

    @discardableResult func subscribe(metadata: AppMetadata, account: Account, onSign: @escaping SigningCallback) async throws -> SubscriptionJWTPayload.Wrapper {

        let dappUrl = metadata.url

        logger.debug("Subscribing for Push")

        let peerPublicKey = try await resolvePublicKey(dappUrl: metadata.url)
        let subscribeTopic = peerPublicKey.rawRepresentation.sha256().toHexString()

        let keysY = try generateAgreementKeys(peerPublicKey: peerPublicKey)

        let responseTopic  = keysY.derivedTopic()
        
        dappsMetadataStore.set(metadata, forKey: responseTopic)

        try kms.setSymmetricKey(keysY.sharedKey, for: subscribeTopic)

        _ = try await identityClient.register(account: account, onSign: onSign)

        try kms.setAgreementSecret(keysY, topic: responseTopic)

        logger.debug("setting symm key for response topic \(responseTopic)")

        let protocolMethod = PushSubscribeProtocolMethod()

        let subscriptionAuthWrapper = try await createJWTWrapper(subscriptionAccount: account, dappUrl: dappUrl)
        let request = RPCRequest(method: protocolMethod.method, params: subscriptionAuthWrapper)

        logger.debug("PushSubscribeRequester: subscribing to response topic: \(responseTopic)")

        try await networkingInteractor.subscribe(topic: responseTopic)

        try await networkingInteractor.request(request, topic: subscribeTopic, protocolMethod: protocolMethod, envelopeType: .type1(pubKey: keysY.publicKey.rawRepresentation))
        return subscriptionAuthWrapper
    }

    private func resolvePublicKey(dappUrl: String) async throws -> AgreementPublicKey {
        logger.debug("PushSubscribeRequester: Resolving DIDDoc for: \(dappUrl)")
        let didDoc = try await webDidResolver.resolveDidDoc(domainUrl: dappUrl)
        guard let keyAgreement = didDoc.keyAgreement.first else { throw Errors.didDocDoesNotContainKeyAgreement }
        guard let verificationMethod = didDoc.verificationMethod.first(where: { verificationMethod in verificationMethod.id == keyAgreement }) else { throw Errors.noVerificationMethodForKey }
        guard verificationMethod.publicKeyJwk.crv == .X25519 else { throw Errors.unsupportedCurve}
        let pubKeyBase64Url = verificationMethod.publicKeyJwk.x
        return try AgreementPublicKey(base64url: pubKeyBase64Url)
    }


    private func generateAgreementKeys(peerPublicKey: AgreementPublicKey) throws -> AgreementKeys {
        let selfPubKey = try kms.createX25519KeyPair()

        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPublicKey.hexRepresentation)
        return keys
    }

    private func createJWTWrapper(subscriptionAccount: Account, dappUrl: String) async throws -> SubscriptionJWTPayload.Wrapper {
        let types = try await subscriptionScopeProvider.getSubscriptionScope(dappUrl: dappUrl)
        let scope = types.map{$0.name}.joined(separator: " ")
        let jwtPayload = SubscriptionJWTPayload(keyserver: keyserverURL, subscriptionAccount: subscriptionAccount, dappUrl: dappUrl, scope: scope)
        return try identityClient.signAndCreateWrapper(
            payload: jwtPayload,
            account: subscriptionAccount
        )
    }
}
