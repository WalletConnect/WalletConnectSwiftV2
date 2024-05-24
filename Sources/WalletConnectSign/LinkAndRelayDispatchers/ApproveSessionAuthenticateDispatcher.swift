import Foundation

actor ApproveSessionAuthenticateDispatcher {

    private let sessionAuthenticateResponder: SessionAuthenticateResponder
    private let linkSessionAuthenticateResponder: LinkSessionAuthenticateResponder
    private let logger: ConsoleLogging
    private let util: ApproveSessionAuthenticateUtil

    init(
        relaySessionAuthenticateResponder: SessionAuthenticateResponder,
        logger: ConsoleLogging,
        rpcHistory: RPCHistory,
        approveSessionAuthenticateUtil: ApproveSessionAuthenticateUtil,
        linkSessionAuthenticateResponder: LinkSessionAuthenticateResponder
    ) {
        self.sessionAuthenticateResponder = relaySessionAuthenticateResponder
        self.logger = logger
        self.util = approveSessionAuthenticateUtil
        self.linkSessionAuthenticateResponder = linkSessionAuthenticateResponder
    }

    public func approveSessionAuthenticate(requestId: RPCID, auths: [Cacao]) async throws -> (Session?, String?) {

        let transportType = try util.getHistoryRecord(requestId: requestId).transportType ?? .relay

        logger.debug("Will approve session authenticate with transport type: \(transportType)")
        switch transportType {

        case .relay:
            let session = try await sessionAuthenticateResponder.respond(requestId: requestId, auths: auths)
            return (session, nil)
        case .linkMode:
            return try await linkSessionAuthenticateResponder.respond(requestId: requestId, auths: auths)
        }
    }

    func respondError(requestId: RPCID) async throws {
        let transportType = try util.getHistoryRecord(requestId: requestId).transportType ?? .relay

        switch transportType {

        case .relay:
            return try await sessionAuthenticateResponder.respondError(requestId: requestId)
        case .linkMode:
            return try await linkSessionAuthenticateResponder.respondError(requestId: requestId)
        }
    }
}
