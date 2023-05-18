
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

    func subscribe(metadata: AppMetadata, account: Account, onSign: @escaping SigningCallback) async throws {

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

        let availableScope = try await subscriptionScopeProvider.getSubscriptionScope(dappUrl: metadata.url)

        let scope = availableScope.map{$0.name}.joined(separator: " ")

        let request = try createJWTRequest(subscriptionAccount: account, dappUrl: dappUrl, scope: scope)

        let protocolMethod = PushSubscribeProtocolMethod()

        logger.debug("PushSubscribeRequester: subscribing to response topic: \(responseTopic)")

        try await networkingInteractor.subscribe(topic: responseTopic)

        try await networkingInteractor.request(request, topic: subscribeTopic, protocolMethod: protocolMethod, envelopeType: .type1(pubKey: keysY.publicKey.rawRepresentation))
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

    private func createJWTRequest(subscriptionAccount: Account, dappUrl: String, scope: String) throws -> RPCRequest {
        let protocolMethod = PushSubscribeProtocolMethod().method
        let jwtPayload = SubscriptionJWTPayload(keyserver: keyserverURL, subscriptionAccount: subscriptionAccount, dappUrl: dappUrl, scope: scope)
        let wrapper = try identityClient.signAndCreateWrapper(
            payload: jwtPayload,
            account: subscriptionAccount
        )
        return RPCRequest(method: protocolMethod, params: wrapper)
    }
}
