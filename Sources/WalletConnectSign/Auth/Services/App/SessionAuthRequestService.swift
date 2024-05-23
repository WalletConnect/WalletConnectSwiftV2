import Foundation

actor SessionAuthRequestService {
    enum Errors: Error {
        case invalidChain
    }
    private let networkingInteractor: NetworkInteracting
    private let appMetadata: AppMetadata
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let iatProvader: IATProvider
    private let authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         appMetadata: AppMetadata,
         logger: ConsoleLogging,
         iatProvader: IATProvider,
         authResponseTopicRecordsStore: CodableStore<AuthResponseTopicRecord>) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.appMetadata = appMetadata
        self.logger = logger
        self.iatProvader = iatProvader
        self.authResponseTopicRecordsStore = authResponseTopicRecordsStore
    }

    func request(params: AuthRequestParams, topic: String) async throws {
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
        logger.debug("AppRequestService: Subscribibg for response topic: \(responseTopic)")
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
        try await networkingInteractor.subscribe(topic: responseTopic)
    }

    private func createRecapUrn(methods: [String]) throws -> String {
        try AuthenticatedSessionRecapUrnFactory.createNamespaceRecap(methods: methods)
    }
}
