
import Foundation

class SessionResponderDispatcher {
    private let relaySessionResponder: SessionResponder
    private let linkSessionResponder: LinkSessionResponder
    private let logger: ConsoleLogging
    private let sessionStore: WCSessionStorage

    init(
        relaySessionResponder: SessionResponder,
        linkSessionResponder: LinkSessionResponder,
        logger: ConsoleLogging,
        sessionStore: WCSessionStorage
    ) {
        self.relaySessionResponder = relaySessionResponder
        self.linkSessionResponder = linkSessionResponder
        self.logger = logger
        self.sessionStore = sessionStore
    }
    
    func respondSessionRequest(topic: String, requestId: RPCID, response: RPCResult) async throws -> String? {

        guard let session = sessionStore.getSession(forTopic: topic), session.acknowledged else {
            logger.debug("Could not find session for topic \(topic)")
            throw WalletConnectError.noSessionMatchingTopic(topic)
        }
        let transportType = session.transportType

        switch transportType {
        case .relay:
            try await relaySessionResponder.respondSessionRequest(topic: topic, requestId: requestId, response: response)
            return nil
        case .linkMode:
            return try await linkSessionResponder.respondSessionRequest(topic: topic, requestId: requestId, response: response)
        }
    }
}

class SessionResponder {
    enum Errors: Error {
        case sessionRequestExpired
    }
    private let logger: ConsoleLogging
    private let sessionStore: WCSessionStorage
    private let networkingInteractor: NetworkInteracting
    private let verifyContextStore: CodableStore<VerifyContext>
    private let sessionRequestsProvider: SessionRequestsProvider
    private let historyService: HistoryService

    init(logger: ConsoleLogging, sessionStore: WCSessionStorage, networkingInteractor: NetworkInteracting, verifyContextStore: CodableStore<VerifyContext>, sessionRequestsProvider: SessionRequestsProvider, historyService: HistoryService) {
        self.logger = logger
        self.sessionStore = sessionStore
        self.networkingInteractor = networkingInteractor
        self.verifyContextStore = verifyContextStore
        self.sessionRequestsProvider = sessionRequestsProvider
        self.historyService = historyService
    }

    func respondSessionRequest(topic: String, requestId: RPCID, response: RPCResult) async throws {
        guard sessionStore.hasSession(forTopic: topic) else {
            throw WalletConnectError.noSessionMatchingTopic(topic)
        }

        let protocolMethod = SessionRequestProtocolMethod()

        guard sessionRequestNotExpired(requestId: requestId) else {
            try await networkingInteractor.respondError(
                topic: topic,
                requestId: requestId,
                protocolMethod: protocolMethod,
                reason: SignReasonCode.sessionRequestExpired
            )
            verifyContextStore.delete(forKey: requestId.string)
            throw Errors.sessionRequestExpired
        }

        try await networkingInteractor.respond(
            topic: topic,
            response: RPCResponse(id: requestId, outcome: response),
            protocolMethod: protocolMethod
        )
        verifyContextStore.delete(forKey: requestId.string)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else {return}
            sessionRequestsProvider.emitRequestIfPending()
        }
    }

    private func sessionRequestNotExpired(requestId: RPCID) -> Bool {
        guard let request = historyService.getSessionRequest(id: requestId)?.request
        else { return false }

        return !request.isExpired()
    }
}

class LinkSessionResponder {
    enum Errors: Error {
        case sessionRequestExpired
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

        let peerUniversalLink = session.peerParticipant.metadata.redirect!.linkMode!

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
