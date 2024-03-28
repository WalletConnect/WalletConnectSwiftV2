//import Foundation
//
//actor ApproveSessionAuthenticateDispatcher {
//
//
//    private let authResponder: AuthResponder
//    private let logger: ConsoleLogging
//    private let rpcHistory: RPCHistory
//
//    init(
//        authResponder: AuthResponder,
//        logger: ConsoleLogging,
//        rpcHistory: RPCHistory
//    ) {
//        self.authResponder = authResponder
//        self.logger = logger
//        self.rpcHistory = rpcHistory
//    }
//
//    public func approveSessionAuthenticate(requestId: RPCID, auths: [Cacao]) async throws -> Session? {
//
//
//        try await authResponder.respond(requestId: requestId, auths: auths)
//    }
//}
