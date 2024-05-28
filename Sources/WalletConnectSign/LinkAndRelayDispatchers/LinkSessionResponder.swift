import Foundation

class LinkSessionResponder {
    enum Errors: Error {
        case sessionRequestExpired
        case missingPeerUniversalLink
    }
    private let logger: ConsoleLogging
    private let sessionStore: WCSessionStorage
    private let linkEnvelopesDispatcher: LinkEnvelopesDispatcher
    private let sessionRequestsProvider: SessionRequestsProvider
    private let historyService: HistoryService

    init(
        logger: ConsoleLogging,
        sessionStore: WCSessionStorage,
        linkEnvelopesDispatcher: LinkEnvelopesDispatcher,
        sessionRequestsProvider: SessionRequestsProvider,
        historyService: HistoryService
    ) {
        self.logger = logger
        self.sessionStore = sessionStore
        self.linkEnvelopesDispatcher = linkEnvelopesDispatcher
        self.sessionRequestsProvider = sessionRequestsProvider
        self.historyService = historyService
    }

    func respondSessionRequest(topic: String, requestId: RPCID, response: RPCResult) async throws -> String {
        guard let session = sessionStore.getSession(forTopic: topic) else {
            throw WalletConnectError.noSessionMatchingTopic(topic)
        }

        guard let peerUniversalLink = session.peerParticipant.metadata.redirect!.universal else {
            throw Errors.missingPeerUniversalLink
        }

        guard sessionRequestNotExpired(requestId: requestId) else {
            try await linkEnvelopesDispatcher.respondError(
                topic: topic,
                requestId: requestId,
                peerUniversalLink: peerUniversalLink,
                reason: SignReasonCode.sessionRequestExpired,
                envelopeType: .type0
            )
            throw Errors.sessionRequestExpired
        }

        let responseEnvelope = try await linkEnvelopesDispatcher.respond(
            topic: topic,
            response: RPCResponse(id: requestId, outcome: response),
            peerUniversalLink: peerUniversalLink,
            envelopeType: .type0
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else {return}
            sessionRequestsProvider.emitRequestIfPending()
        }
        return responseEnvelope
    }

    private func sessionRequestNotExpired(requestId: RPCID) -> Bool {
        guard let request = historyService.getSessionRequest(id: requestId)?.request
        else { return false }

        return !request.isExpired()
    }
}
