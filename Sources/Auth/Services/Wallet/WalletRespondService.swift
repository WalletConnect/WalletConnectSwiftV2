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

    func respond(params: RespondParams, account: Account) async throws {
        guard let request = rpcHistory.get(recordId: RPCID(params.id))?.request
        else { throw ErrorCode.malformedRequestParams }

        guard let authRequestParams = try request.params?.get(AuthRequestParams.self)
        else { throw ErrorCode.malformedRequestParams }

        let peerPubKey = try AgreementPublicKey(hex: authRequestParams.requester.publicKey)
        let responseTopic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.hexRepresentation)
        try kms.setAgreementSecret(agreementKeys, topic: responseTopic)

        let didpkh = DIDPKH(account: account)
        let cacao = CacaoFormatter().format(authRequestParams, params.signature, didpkh)
        let response = RPCResponse(id: request.id!, result: cacao)

        try await networkingInteractor.respond(topic: params.topic, response: response, tag: AuthResponseParams.tag, envelopeType: .type1(pubKey: selfPubKey.rawRepresentation))
    }
}
