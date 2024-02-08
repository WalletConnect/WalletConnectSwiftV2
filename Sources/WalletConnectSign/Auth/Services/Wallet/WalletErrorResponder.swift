import Foundation

actor WalletErrorResponder {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedAuthRequestParams
    }

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         rpcHistory: RPCHistory) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.rpcHistory = rpcHistory
    }

    func respondError(_ error: AuthError, requestId: RPCID) async throws {
        let authRequestParams = try getAuthRequestParams(requestId: requestId)
        let (topic, keys) = try generateAgreementKeys(requestParams: authRequestParams)

        try kms.setAgreementSecret(keys, topic: topic)

        let envelopeType = Envelope.EnvelopeType.type1(pubKey: keys.publicKey.rawRepresentation)
        try await networkingInteractor.respondError(topic: topic, requestId: requestId, protocolMethod: SessionAuthenticatedProtocolMethod(), reason: error, envelopeType: envelopeType)
    }

    private func getAuthRequestParams(requestId: RPCID) throws -> SessionAuthenticateRequestParams {
        guard let request = rpcHistory.get(recordId: requestId)?.request
        else { throw Errors.recordForIdNotFound }

        guard let authRequestParams = try request.params?.get(SessionAuthenticateRequestParams.self)
        else { throw Errors.malformedAuthRequestParams }

        return authRequestParams
    }

    private func generateAgreementKeys(requestParams: SessionAuthenticateRequestParams) throws -> (topic: String, keys: AgreementKeys) {
        let peerPubKey = try AgreementPublicKey(hex: requestParams.requester.publicKey)
        let topic = peerPubKey.rawRepresentation.sha256().toHexString()
        let selfPubKey = try kms.createX25519KeyPair()
        let keys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.hexRepresentation)
        // TODO -  remove keys
        return (topic, keys)
    }
}

extension WalletErrorResponder.Errors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .recordForIdNotFound:
            return NSLocalizedString("The record for the specified ID was not found.", comment: "Record Not Found Error")
        case .malformedAuthRequestParams:
            return NSLocalizedString("The authentication request parameters are malformed.", comment: "Malformed Auth Request Params Error")
        }
    }
}
