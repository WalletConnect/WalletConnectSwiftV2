import WalletConnectNetworking
import Foundation

class PushRequestResponder {
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

        let requestRecord = try getRecord(requestId: requestId)
        let peerPublicKey = try getPeerPublicKey(for: requestRecord)
        let pairingTopic = requestRecord.topic

        let keys = try generateAgreementKeys(peerPublicKey: peerPublicKey)
        let pushTopic = keys.derivedTopic()

        try kms.setAgreementSecret(keys, topic: pushTopic)
        try await networkingInteractor.subscribe(topic: pushTopic)

        let responseParams = PushResponseParams(publicKey: keys.publicKey.hexRepresentation)

        let response = RPCResponse(id: requestId, result: responseParams)
        try await networkingInteractor.respond(topic: pairingTopic, response: response, protocolMethod: PushRequestProtocolMethod())
    }

    func respondError(requestId: RPCID) async throws {
        //TODO
        fatalError("not implemented")

        let requestRecord = try getRecord(requestId: requestId)
        let pairingTopic = requestRecord.topic

        try await networkingInteractor.respondError(topic: pairingTopic, requestId: requestId, protocolMethod: PushRequestProtocolMethod(), reason: PushError.rejected)


    }

    private func getRecord(requestId: RPCID) throws -> RPCHistory.Record {
        guard let record = rpcHistory.get(recordId: requestId)
        else { throw Errors.recordForIdNotFound }
        return record
    }

    private func getPeerPublicKey(for record: RPCHistory.Record) throws -> AgreementPublicKey {
        guard let params = try record.request.params?.get(PushResponseParams.self)
        else { throw Errors.malformedRequestParams }

        let peerPublicKey = try AgreementPublicKey(hex: params.publicKey)
        return peerPublicKey
    }

    private func generateAgreementKeys(peerPublicKey: AgreementPublicKey) throws -> AgreementKeys {
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPublicKey.hexRepresentation)
        return keys
    }
}

