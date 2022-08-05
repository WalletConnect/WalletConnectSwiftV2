import Foundation
import WalletConnectKMS
import JSONRPC
import WalletConnectUtils

actor AuthRespondService {
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

    func respond(respondParams: RespondParams, issuer: Account) async throws {
        guard let request = rpcHistory.get(recordId: RPCID(respondParams.id))?.request else { throw Errors.recordForIdNotFound }
        guard let authRequestParams = try? request.params?.get(AuthRequestParams.self) else { throw Errors.malformedAuthRequestParams }

        let peerPubKey = authRequestParams.requester.publicKey
        let responseTopic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey)
        try kms.setAgreementSecret(agreementKeys, topic: responseTopic)

        let cacao = CacaoFormatter().format(authRequestParams, respondParams.signature, issuer)
        let response = RPCResponse(id: request.id!, result: cacao)

        try await networkingInteractor.respond(topic: respondParams.topic, response: response, tag: AuthResponseParams.tag, envelopeType: .type1(pubKey: selfPubKey.rawRepresentation))
    }
}
