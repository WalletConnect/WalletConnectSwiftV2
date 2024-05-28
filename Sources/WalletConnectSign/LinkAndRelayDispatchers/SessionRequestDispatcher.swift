
import Foundation

final class SessionRequestDispatcher {
    private let relaySessionRequester: SessionRequester
    private let linkSessionRequester: LinkSessionRequester
    private let logger: ConsoleLogging
    private let sessionStore: WCSessionStorage

    init(
        relaySessionRequester: SessionRequester,
        linkSessionRequester: LinkSessionRequester,
        logger: ConsoleLogging,
        sessionStore: WCSessionStorage
    ) {
        self.relaySessionRequester = relaySessionRequester
        self.linkSessionRequester = linkSessionRequester
        self.logger = logger
        self.sessionStore = sessionStore
    }

    public func request(_ request: Request) async throws -> String? {

        guard let session = sessionStore.getSession(forTopic: request.topic), session.acknowledged else {
            logger.debug("Could not find session for topic \(request.topic)")
            throw WalletConnectError.noSessionMatchingTopic(request.topic)
        }
        let transportType = session.transportType
        logger.debug("Will send session request on transport type: \(transportType)")

        switch transportType {
        case .relay:
            try await relaySessionRequester.request(request)
            return nil
        case .linkMode:
            return try await linkSessionRequester.request(request)
        }
    }
}




