import Foundation
import WalletConnectUtils
import WalletConnectKMS
import JSONRPC

actor AuthRequestService {
    private let networkingInteractor: NetworkInteracting
    private let appMetadata: AppMetadata
    private let kms: KeyManagementService

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementService,
         appMetadata: AppMetadata) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.appMetadata = appMetadata
    }

    func request(params: RequestParams, topic: String) async throws {
        let pubKey = try kms.createX25519KeyPair()
        let responseTopic = pubKey.rawRepresentation.sha256().toHexString()
        let requester = AuthRequestParams.Requester(publicKey: pubKey.hexRepresentation, metadata: appMetadata)
        let issueAt = ISO8601DateFormatter().string(from: Date())
        let payload = AuthPayload(requestParams: params, iat: issueAt)
        let params = AuthRequestParams(requester: requester, payloadParams: payload)
        let request = RPCRequest(method: "wc_authRequest", params: params)
        try await networkingInteractor.request(request, topic: topic, tag: AuthRequestParams.tag)
        try await networkingInteractor.subscribe(topic: responseTopic)
    }
}
