
import Foundation

actor LinkAuthRequester {
    enum Errors: Error {
        case invalidChain
    }
    private let appMetadata: AppMetadata
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let iatProvader: IATProvider
    private let authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>
    private let linkEnvelopesDispatcher: LinkEnvelopesDispatcher

    init(kms: KeyManagementService,
         appMetadata: AppMetadata,
         logger: ConsoleLogging,
         iatProvader: IATProvider,
         authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>,
         linkEnvelopesDispatcher: LinkEnvelopesDispatcher) {
        self.kms = kms
        self.appMetadata = appMetadata
        self.logger = logger
        self.iatProvader = iatProvader
        self.authResponseTopicRecordsStore = authResponseTopicRecordsStore
        self.linkEnvelopesDispatcher = linkEnvelopesDispatcher
    }

    func request(params: AuthRequestParams, walletUniversalLink: String) async throws -> String {


        print("LinkAuthRequester: creating request")
        var params = params
        let pubKey = try kms.createX25519KeyPair()
        let responseTopic = pubKey.rawRepresentation.sha256().toHexString()
        let protocolMethod = SessionAuthenticatedProtocolMethod(ttl: params.ttl)
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

        

        return try await linkEnvelopesDispatcher.request(topic: UUID().uuidString,request: request, peerUniversalLink: walletUniversalLink, envelopeType: .type2)

    }

    private func createRecapUrn(methods: [String]) throws -> String {
        try AuthenticatedSessionRecapUrnFactory.createNamespaceRecap(methods: methods)
    }
}
