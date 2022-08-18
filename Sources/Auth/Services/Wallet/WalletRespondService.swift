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
    
    func respond(result: Result<RespondParams, ErrorCode>, account: Account) async throws {
        switch result {
        case .success(let params):
            try await respond(respondParams: params, account: account)
        case .failure(let error):
            fatalError("TODO respond with error")
        }
    }

    private func respond(respondParams: RespondParams, account: Account) async throws {
        guard let request = rpcHistory.get(recordId: respondParams.id)?.request else { throw Errors.recordForIdNotFound }
        guard let authRequestParams = try? request.params?.get(AuthRequestParams.self) else { throw Errors.malformedAuthRequestParams }

        let peerPubKey = authRequestParams.requester.publicKey
        let responseTopic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey)
        try kms.setAgreementSecret(agreementKeys, topic: responseTopic)

        let didpkh = DIDPKH(account: account)
        let cacao = CacaoFormatter().format(authRequestParams, respondParams.signature, didpkh)
        let response = RPCResponse(id: request.id!, result: cacao)

        try await networkingInteractor.respond(topic: responseTopic, response: response, tag: AuthResponseParams.tag, envelopeType: .type1(pubKey: selfPubKey.rawRepresentation))
    }
}
