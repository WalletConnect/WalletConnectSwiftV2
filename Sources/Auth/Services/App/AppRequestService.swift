import Foundation

actor AppRequestService {
    private let networkingInteractor: NetworkInteracting
    private let appMetadata: AppMetadata
    private let kms: KeyManagementService
    private let logger: ConsoleLogging
    private let iatProvader: IATProvider

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         appMetadata: AppMetadata,
         logger: ConsoleLogging,
         iatProvader: IATProvider) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.appMetadata = appMetadata
        self.logger = logger
        self.iatProvader = iatProvader
    }

    func request(params: RequestParams, topic: String) async throws {
        let pubKey = try kms.createX25519KeyPair()
        let responseTopic = pubKey.rawRepresentation.sha256().toHexString()
        let requester = AuthRequestParams.Requester(publicKey: pubKey.hexRepresentation, metadata: appMetadata)
        let payload = AuthPayload(requestParams: params, iat: iatProvader.iat)
        let params = AuthRequestParams(requester: requester, payloadParams: payload)
        let request = RPCRequest(method: "wc_authRequest", params: params)
        try kms.setPublicKey(publicKey: pubKey, for: responseTopic)
        logger.debug("AppRequestService: Subscribibg for response topic: \(responseTopic)")
        try await networkingInteractor.request(request, topic: topic, protocolMethod: AuthRequestProtocolMethod())
        try await networkingInteractor.subscribe(topic: responseTopic)
    }
}
