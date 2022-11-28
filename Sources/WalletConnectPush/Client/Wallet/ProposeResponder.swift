import WalletConnectNetworking
import Foundation

class ProposeResponder {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedRequestParams
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

    func respond(requestId: RPCID) async throws {
        logger.debug("Approving Push Proposal")
        let peerPublicKey = try getPeerPublicKey(requestId: requestId)
        let (topic, keys) = try generateAgreementKeys(peerPublicKey: peerPublicKey)

        try kms.setAgreementSecret(keys, topic: topic)

        let responseParams = PushResponseParams(publicKey: keys.publicKey.hexRepresentation)

        let response = RPCResponse(id: requestId, result: responseParams)
        try await networkingInteractor.respond(topic: topic, response: response, protocolMethod: PushProposeProtocolMethod(), envelopeType: .type1(pubKey: keys.publicKey.rawRepresentation))
    }

    func respondError(requestId: RPCID) async throws {
        //TODO
        fatalError("not implemented")
    }

    private func getPeerPublicKey(requestId: RPCID) throws -> AgreementPublicKey {
        guard let request = rpcHistory.get(recordId: requestId)?.request
        else { throw Errors.recordForIdNotFound }

        guard let params = try request.params?.get(PushResponseParams.self)
        else { throw Errors.malformedRequestParams }

        let peerPublicKey = try AgreementPublicKey(hex: params.publicKey)
        return peerPublicKey
    }

    private func generateAgreementKeys(peerPublicKey: AgreementPublicKey) throws -> (topic: String, keys: AgreementKeys) {
        let topic = peerPublicKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPublicKey.hexRepresentation)
        return (topic, keys)
    }
}
