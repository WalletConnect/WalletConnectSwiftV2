
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

        guard let session = sessionStore.getSession(forTopic: topic) else {
            logger.debug("Could not find session for topic \(topic)")
            throw WalletConnectError.noSessionMatchingTopic(topic)
        }
        let transportType = session.transportType
        logger.debug("Will respond session request with transport type: \(transportType)")

        switch transportType {
        case .relay:
            try await relaySessionResponder.respondSessionRequest(topic: topic, requestId: requestId, response: response)
            return nil
        case .linkMode:
            logger.debug("will call linkSessionResponder.respondSessionRequest()")
            return try await linkSessionResponder.respondSessionRequest(topic: topic, requestId: requestId, response: response)
        }
    }
}
