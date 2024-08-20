import Foundation

actor WalletErrorResponder {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedAuthRequestParams
        case peerUniversalLinkNotFound
        case linkModeNotSupported
    }

    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging
    private let linkEnvelopesDispatcher: LinkEnvelopesDispatcher
    private let eventsClient: EventsClientProtocol

    init(networkingInteractor: NetworkInteracting,
         logger: ConsoleLogging,
         kms: KeyManagementServiceProtocol,
         rpcHistory: RPCHistory,
         linkEnvelopesDispatcher: LinkEnvelopesDispatcher,
         eventsClient: EventsClientProtocol
    ) {
        self.networkingInteractor = networkingInteractor
        self.logger = logger
        self.kms = kms
        self.rpcHistory = rpcHistory
        self.linkEnvelopesDispatcher = linkEnvelopesDispatcher
        self.eventsClient = eventsClient
    }

    func respondError(_ error: AuthError, requestId: RPCID) async throws -> String? {

        let transportType = try getHistoryRecord(requestId: requestId).transportType ?? .relay

        let authRequestParams = try getAuthRequestParams(requestId: requestId)
        let (topic, keys) = try generateAgreementKeys(requestParams: authRequestParams)

        try kms.setAgreementSecret(keys, topic: topic)

        let type1EnvelopeKey = keys.publicKey.rawRepresentation
        switch transportType {
        case .relay:
            try await respondErrorRelay(error, requestId: requestId, topic: topic, type1EnvelopeKey: type1EnvelopeKey)
            return nil
        case .linkMode:
            return try await respondErrorLinkMode(error, requestId: requestId, topic: topic, type1EnvelopeKey: type1EnvelopeKey)
        }
    }

    private func respondErrorRelay(_ error: AuthError, requestId: RPCID, topic: String, type1EnvelopeKey: Data) async throws {
        let envelopeType = Envelope.EnvelopeType.type1(pubKey: type1EnvelopeKey)
        try await networkingInteractor.respondError(
            topic: topic,
            requestId: requestId,
            protocolMethod: SessionAuthenticatedProtocolMethod.responseReject(),
            reason: error,
            envelopeType: envelopeType
        )
    }

    private func respondErrorLinkMode(_ error: AuthError, requestId: RPCID, topic: String, type1EnvelopeKey: Data) async throws -> String {
        let (sessionAuthenticateRequestParams, _) = try getsessionAuthenticateRequestParams(requestId: requestId)

        guard let redirect = sessionAuthenticateRequestParams.requester.metadata.redirect,
              let linkMode = redirect.linkMode,
              linkMode == true else {
            throw Errors.linkModeNotSupported
        }
        guard let peerUniversalLink = redirect.universal else {
            throw Errors.peerUniversalLinkNotFound
        }

        let envelope = try await linkEnvelopesDispatcher.respondError(topic: topic, requestId: requestId, peerUniversalLink: peerUniversalLink, reason: error, envelopeType: .type1(pubKey: type1EnvelopeKey))

        Task(priority: .low) { eventsClient.saveMessageEvent(.sessionAuthenticateLinkModeResponseRejectSent(requestId)) }

        return envelope

    }

    func getsessionAuthenticateRequestParams(requestId: RPCID) throws -> (request: SessionAuthenticateRequestParams, topic: String) {
        let record = try getHistoryRecord(requestId: requestId)

        let request = record.request
        guard let authRequestParams = try request.params?.get(SessionAuthenticateRequestParams.self)
        else { throw Errors.malformedAuthRequestParams }

        return (request: authRequestParams, topic: record.topic)
    }

    func getHistoryRecord(requestId: RPCID) throws -> RPCHistory.Record {
        guard let record = rpcHistory.get(recordId: requestId)
        else { throw Errors.recordForIdNotFound }
        return record
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
        case .peerUniversalLinkNotFound:
            return NSLocalizedString("The peer's universal link was not found.", comment: "Peer Universal Link Not Found Error")
        case .linkModeNotSupported:
            return NSLocalizedString("Link mode is not supported.", comment: "Link Mode Not Supported Error")
        }
    }
}
