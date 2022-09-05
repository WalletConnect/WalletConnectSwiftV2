import Foundation
import JSONRPC
import WalletConnectNetworking
import WalletConnectUtils
import WalletConnectKMS

actor AppRequestService {
    private let networkingInteractor: NetworkInteracting
    private let appMetadata: AppMetadata
    private let kms: KeyManagementService
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         appMetadata: AppMetadata,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.appMetadata = appMetadata
        self.logger = logger
    }

    func request(params: RequestParams, topic: String) async throws {
        let pubKey = try kms.createX25519KeyPair()
        let responseTopic = pubKey.rawRepresentation.sha256().toHexString()
        let requester = AuthRequestParams.Requester(publicKey: pubKey.hexRepresentation, metadata: appMetadata)
        let issueAt = ISO8601DateFormatter().string(from: Date())
        let payload = AuthPayload(requestParams: params, iat: issueAt)
        let params = AuthRequestParams(requester: requester, payloadParams: payload)
        let request = RPCRequest(method: "wc_authRequest", params: params)
        try kms.setPublicKey(publicKey: pubKey, for: responseTopic)
        logger.debug("AppRequestService: Subscribibg for response topic: \(responseTopic)")
        try await networkingInteractor.requestNetworkAck(request, topic: topic, tag: AuthProtocolMethod.request.tag)
        try await networkingInteractor.subscribe(topic: responseTopic)
    }
}
