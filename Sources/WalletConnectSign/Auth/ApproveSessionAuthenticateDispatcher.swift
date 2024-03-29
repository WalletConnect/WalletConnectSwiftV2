import Foundation

actor ApproveSessionAuthenticateDispatcher {

    private let relaySessionAuthenticateResponder: SessionAuthenticateResponder
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
        self.relaySessionAuthenticateResponder = relaySessionAuthenticateResponder
        self.logger = logger
        self.util = approveSessionAuthenticateUtil
        self.linkSessionAuthenticateResponder = linkSessionAuthenticateResponder
    }

    public func approveSessionAuthenticate(requestId: RPCID, auths: [Cacao]) async throws -> Session? {

        let transportType = try util.getHistoryRecord(requestId: requestId).transportType

        switch transportType {

        case .relay:
            return try await relaySessionAuthenticateResponder.respond(requestId: requestId, auths: auths)
        case .linkMode:
            return try await linkSessionAuthenticateResponder.respond(requestId: requestId, auths: auths)
        }
    }
}
