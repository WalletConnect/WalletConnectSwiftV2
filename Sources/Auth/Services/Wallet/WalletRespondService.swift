import Foundation
import WalletConnectKMS
import JSONRPC
import WalletConnectUtils

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

    func respond(requestId: RPCID, result: Result<CacaoSignature, ExternalError>, account: Account) async throws {
        switch result {
        case .success(let signature):
            try await respond(requestId: requestId, signature: signature, account: account)
        case .failure(let error):
            try await respond(error: error, requestId: requestId)
        }
    }

    private func respond(requestId: RPCID, signature: CacaoSignature, account: Account) async throws {
        let authRequestParams = try getAuthRequestParams(requestId: requestId)
        let (topic, keys) = try generateAgreementKeys(requestParams: authRequestParams)

        try kms.setAgreementSecret(keys, topic: topic)

        let didpkh = DIDPKH(account: account)
        let cacao = CacaoFormatter().format(authRequestParams, signature, didpkh)
        let response = RPCResponse(id: requestId, result: cacao)
        try await networkingInteractor.respond(topic: topic, response: response, tag: AuthResponseParams.tag, envelopeType: .type1(pubKey: keys.publicKey.rawRepresentation))
    }

    private func respond(error: ExternalError, requestId: RPCID) async throws {
        let authRequestParams = try getAuthRequestParams(requestId: requestId)
        let (topic, keys) = try generateAgreementKeys(requestParams: authRequestParams)

        try kms.setAgreementSecret(keys, topic: topic)

        let tag = AuthResponseParams.tag
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
        let peerPubKey = requestParams.requester.publicKey
        let topic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey)
        return (topic, keys)
    }
}
