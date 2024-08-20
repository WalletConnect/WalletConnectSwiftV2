
import Foundation

actor LinkAuthRequester {
    public enum Errors: Error {
        case invalidChain
        case walletLinkSupportNotProven
    }
    private let appMetadata: AppMetadata
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let iatProvader: IATProvider
    private let authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>
    private let linkEnvelopesDispatcher: LinkEnvelopesDispatcher
    private let linkModeLinksStore: CodableStore<Bool>
    private let eventsClient: EventsClientProtocol

    init(kms: KeyManagementService,
         appMetadata: AppMetadata,
         logger: ConsoleLogging,
         iatProvader: IATProvider,
         authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>,
         linkEnvelopesDispatcher: LinkEnvelopesDispatcher,
         linkModeLinksStore: CodableStore<Bool>,
         eventsClient: EventsClientProtocol) {
        self.kms = kms
        self.appMetadata = appMetadata
        self.logger = logger
        self.iatProvader = iatProvader
        self.authResponseTopicRecordsStore = authResponseTopicRecordsStore
        self.linkEnvelopesDispatcher = linkEnvelopesDispatcher
        self.linkModeLinksStore = linkModeLinksStore
        self.eventsClient = eventsClient
    }

    func request(params: AuthRequestParams, walletUniversalLink: String) async throws -> String {
        guard try linkModeLinksStore.get(key: walletUniversalLink) != nil else { throw Errors.walletLinkSupportNotProven }

        var params = params
        let pubKey = try kms.createX25519KeyPair()
        let responseTopic = pubKey.rawRepresentation.sha256().toHexString()
        let protocolMethod = SessionAuthenticatedProtocolMethod.responseApprove(ttl: params.ttl)
        guard let chainNamespace = Blockchain(params.chains.first!)?.namespace,
              chainNamespace == "eip155"
        else {
            throw Errors.invalidChain
        }
        if let methods = params.methods,
           !methods.isEmpty {
            let namespaceRecap = try createRecapUrn(methods: methods)
            params.addResource(resource: namespaceRecap)
        }
        let requester = Participant(publicKey: pubKey.hexRepresentation, metadata: appMetadata)
        let payload = AuthPayload(requestParams: params, iat: iatProvader.iat)

        let sessionAuthenticateRequestParams = SessionAuthenticateRequestParams(requester: requester, authPayload: payload, ttl: params.ttl)
        let authResponseTopicRecord = AuthResponseTopicRecord(topic: responseTopic, unixTimestamp: sessionAuthenticateRequestParams.expiryTimestamp)
        authResponseTopicRecordsStore.set(authResponseTopicRecord, forKey: responseTopic)
        let request = RPCRequest(method: protocolMethod.method, params: sessionAuthenticateRequestParams)
        try kms.setPublicKey(publicKey: pubKey, for: responseTopic)

        logger.debug("LinkAuthRequester: sending request")        

        let envelope = try await linkEnvelopesDispatcher.request(topic: UUID().uuidString,request: request, peerUniversalLink: walletUniversalLink, envelopeType: .type2)

        Task { eventsClient.saveMessageEvent(.sessionAuthenticateLinkModeSent(request.id!)) }
        return envelope
    }

    private func createRecapUrn(methods: [String]) throws -> String {
        try AuthenticatedSessionRecapUrnFactory.createNamespaceRecap(methods: methods)
    }
}

extension LinkAuthRequester.Errors {
    var localizedDescription: String {
        switch self {
        case .invalidChain:
            return "The specified blockchain is invalid or unsupported."
        case .walletLinkSupportNotProven:
            return "Wallet link support has not been proven for the specified operation."
        }
    }
}
