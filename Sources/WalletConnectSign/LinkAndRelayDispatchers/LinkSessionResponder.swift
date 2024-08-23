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
    private let eventsClient: EventsClientProtocol

    init(
        logger: ConsoleLogging,
        sessionStore: WCSessionStorage,
        linkEnvelopesDispatcher: LinkEnvelopesDispatcher,
        sessionRequestsProvider: SessionRequestsProvider,
        historyService: HistoryService,
        eventsClient: EventsClientProtocol
    ) {
        self.logger = logger
        self.sessionStore = sessionStore
        self.linkEnvelopesDispatcher = linkEnvelopesDispatcher
        self.sessionRequestsProvider = sessionRequestsProvider
        self.historyService = historyService
        self.eventsClient = eventsClient
    }

    func respondSessionRequest(topic: String, requestId: RPCID, response: RPCResult) async throws -> String {
        logger.debug("LinkSessionResponder: responding session request")
        guard let session = sessionStore.getSession(forTopic: topic) else {
            let error = WalletConnectError.noSessionMatchingTopic(topic)
            logger.debug("failed: \(error)")
            throw error
        }

        guard let peerUniversalLink = session.peerParticipant.metadata.redirect!.universal else {
            let error = Errors.missingPeerUniversalLink
            logger.debug("failed: \(error)")
            throw error
        }

        guard sessionRequestNotExpired(requestId: requestId) else {
            logger.debug("request expired")
            
            try await linkEnvelopesDispatcher.respondError(
                topic: topic,
                requestId: requestId,
                peerUniversalLink: peerUniversalLink,
                reason: SignReasonCode.sessionRequestExpired,
                envelopeType: .type0
            )
            Task(priority: .low) { eventsClient.saveMessageEvent(.sessionRequestLinkModeResponseSent(requestId)) }

            throw Errors.sessionRequestExpired
        }

        logger.debug("will call linkEnvelopesDispatcher.respond()")
        let responseEnvelope = try await linkEnvelopesDispatcher.respond(
            topic: topic,
            response: RPCResponse(id: requestId, outcome: response),
            peerUniversalLink: peerUniversalLink,
            envelopeType: .type0
        )
        Task(priority: .low) { eventsClient.saveMessageEvent(.sessionRequestLinkModeResponseSent(requestId)) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else {return}
            sessionRequestsProvider.emitRequestIfPending()
        }
        logger.debug("will return response envelope: \(responseEnvelope)")
        return responseEnvelope
    }

    private func sessionRequestNotExpired(requestId: RPCID) -> Bool {
        guard let request = historyService.getSessionRequest(id: requestId)?.request
        else { return false }

        return !request.isExpired()
    }
}
