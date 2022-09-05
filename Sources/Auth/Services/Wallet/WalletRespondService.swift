import Foundation
import JSONRPC
import WalletConnectKMS
import WalletConnectUtils
import WalletConnectNetworking

actor WalletRespondService {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedAuthRequestParams
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementService,
         rpcHistory: RPCHistory) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.rpcHistory = rpcHistory
    }

    func respond(requestId: RPCID, signature: CacaoSignature, account: Account) async throws {
        let authRequestParams = try getAuthRequestParams(requestId: requestId)
        let (topic, keys) = try generateAgreementKeys(requestParams: authRequestParams)

        try kms.setAgreementSecret(keys, topic: topic)

        let didpkh = DIDPKH(account: account)
        let cacao = CacaoFormatter().format(authRequestParams, signature, didpkh)
        let response = RPCResponse(id: requestId, result: cacao)
        try await networkingInteractor.respond(topic: topic, response: response, tag: AuthProtocolMethod.authRequest.responseTag, envelopeType: .type1(pubKey: keys.publicKey.rawRepresentation))
    }

    func respondError(requestId: RPCID) async throws {
        let authRequestParams = try getAuthRequestParams(requestId: requestId)
        let (topic, keys) = try generateAgreementKeys(requestParams: authRequestParams)

        try kms.setAgreementSecret(keys, topic: topic)

        let tag = AuthProtocolMethod.authRequest.responseTag
        let error = AuthError.userRejeted
        let envelopeType = Envelope.EnvelopeType.type1(pubKey: keys.publicKey.rawRepresentation)
        try await networkingInteractor.respondError(topic: topic, requestId: requestId, tag: tag, reason: error, envelopeType: envelopeType)
    }

    private func getAuthRequestParams(requestId: RPCID) throws -> AuthRequestParams {
        guard let request = rpcHistory.get(recordId: requestId)?.request
        else { throw Errors.recordForIdNotFound }

        guard let authRequestParams = try request.params?.get(AuthRequestParams.self)
        else { throw Errors.malformedAuthRequestParams }

        return authRequestParams
    }

    private func generateAgreementKeys(requestParams: AuthRequestParams) throws -> (topic: String, keys: AgreementKeys) {
        let peerPubKey = try AgreementPublicKey(hex: requestParams.requester.publicKey)
        let topic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.hexRepresentation)
        return (topic, keys)
    }
}
