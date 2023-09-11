
import Foundation

class NotifySubscribeRequester {

    enum Errors: Error {
        case signatureRejected
    }

    private let keyserverURL: URL
    private let identityClient: IdentityClient
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let webDidResolver: WebDidResolver
    private let dappsMetadataStore: CodableStore<AppMetadata>
    private let notifyConfigProvider: NotifyConfigProvider

    init(keyserverURL: URL,
         networkingInteractor: NetworkInteracting,
         identityClient: IdentityClient,
         logger: ConsoleLogging,
         kms: KeyManagementService,
         webDidResolver: WebDidResolver,
         notifyConfigProvider: NotifyConfigProvider,
         dappsMetadataStore: CodableStore<AppMetadata>
    ) {
        self.keyserverURL = keyserverURL
        self.identityClient = identityClient
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.webDidResolver = webDidResolver
        self.dappsMetadataStore = dappsMetadataStore
        self.notifyConfigProvider = notifyConfigProvider
    }

    @discardableResult func subscribe(dappUrl: String, account: Account, onSign: @escaping SigningCallback) async throws -> NotifySubscriptionPayload.Wrapper {

        logger.debug("Subscribing for Notify, dappUrl: \(dappUrl)")

        let metadata = try await notifyConfigProvider.getMetadata(dappUrl: dappUrl)

        let peerPublicKey = try await webDidResolver.resolveAgreementKey(domain: metadata.url)
        let subscribeTopic = peerPublicKey.rawRepresentation.sha256().toHexString()

        let keysY = try generateAgreementKeys(peerPublicKey: peerPublicKey)

        let responseTopic = keysY.derivedTopic()
        
        dappsMetadataStore.set(metadata, forKey: responseTopic)

        try kms.setSymmetricKey(keysY.sharedKey, for: subscribeTopic)
        try kms.setAgreementSecret(keysY, topic: responseTopic)

        logger.debug("setting symm key for response topic \(responseTopic)")

        let protocolMethod = NotifySubscribeProtocolMethod()

        let subscriptionAuthWrapper = try await createJWTWrapper(
            dappPubKey: DIDKey(did: peerPublicKey.did),
            subscriptionAccount: account,
            dappUrl: dappUrl
        )
        let request = RPCRequest(method: protocolMethod.method, params: subscriptionAuthWrapper)

        logger.debug("Subscribing to response topic: \(responseTopic)")

        try await networkingInteractor.subscribe(topic: responseTopic)

        try await networkingInteractor.request(request, topic: subscribeTopic, protocolMethod: protocolMethod, envelopeType: .type1(pubKey: keysY.publicKey.rawRepresentation))
        return subscriptionAuthWrapper
    }

    private func generateAgreementKeys(peerPublicKey: AgreementPublicKey) throws -> AgreementKeys {
        let selfPubKey = try kms.createX25519KeyPair()

        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPublicKey.hexRepresentation)
        return keys
    }

    private func createJWTWrapper(dappPubKey: DIDKey, subscriptionAccount: Account, dappUrl: String) async throws -> NotifySubscriptionPayload.Wrapper {
        let types = try await notifyConfigProvider.getSubscriptionScope(dappUrl: dappUrl)
        let scope = types.map{$0.name}.joined(separator: " ")
        let jwtPayload = NotifySubscriptionPayload(dappPubKey: dappPubKey, keyserver: keyserverURL, subscriptionAccount: subscriptionAccount, dappUrl: dappUrl, scope: scope)
        return try identityClient.signAndCreateWrapper(
            payload: jwtPayload,
            account: subscriptionAccount
        )
    }
}
