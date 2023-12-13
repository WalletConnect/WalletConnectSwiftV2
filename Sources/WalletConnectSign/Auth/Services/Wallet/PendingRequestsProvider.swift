import Foundation

class PendingRequestsProvider {
    private let rpcHistory: RPCHistory
    private let verifyContextStore: CodableStore<VerifyContext>

    init(
        rpcHistory: RPCHistory,
        verifyContextStore: CodableStore<VerifyContext>
    ) {
        self.rpcHistory = rpcHistory
        self.verifyContextStore = verifyContextStore
    }

    public func getPendingRequests() throws -> [(AuthenticationRequest, VerifyContext?)] {
        let pendingRequests: [AuthenticationRequest] = rpcHistory.getPending()
            .filter {$0.request.method == "wc_sessionAuthenticate"}
            .compactMap {
                guard let params = try? $0.request.params?.get(SessionAuthenticateRequestParams.self) else { return nil }
                return AuthenticationRequest(id: $0.request.id!, topic: $0.topic, payload: params.authPayload, requester: params.requester.metadata)
            }
        
        return pendingRequests.map { ($0, try? verifyContextStore.get(key: $0.id.string)) }
    }
}
