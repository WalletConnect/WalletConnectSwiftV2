import Foundation
import WalletConnectKMS
import JSONRPC
import WalletConnectUtils

actor AuthRespondService {
    enum Errors: Error {
        case recordForIdNotFound
    }
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementService
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementService) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.logger = logger
    }

    func respond(respondParams: RespondParams) async throws {

        guard let request = rpcHistory.get(recordId: RPCID(respondParams.id))?.request else { throw Errors.recordForIdNotFound }

        guard let authRequestParams = try? request.params?.get(AuthRequestParams.self) else {
            logger.debug("Malformed auth request params")
            return
        }

        let peerPubKey = authRequestParams.requester.publicKey
        let responseTopic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey)
        try kms.setAgreementSecret(agreementKeys, topic: responseTopic)


        let cacao =
        let response = RPCResponse(id: request.id, result: cacao)



        networkingInteractor.respond(topic: respondParams.topic, response: response, tag: AuthResponseParams.tag, envelopeType: .type1(pubKey: selfPubKey.rawRepresentation))

//        B sends response on response topic.
    }
}
