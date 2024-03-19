import Foundation

class Auth_PendingRequestsProvider {
    private let rpcHistory: RPCHistory
    private let verifyContextStore: CodableStore<VerifyContext>

    init(
        rpcHistory: RPCHistory,
        verifyContextStore: CodableStore<VerifyContext>
    ) {
        self.rpcHistory = rpcHistory
        self.verifyContextStore = verifyContextStore
    }

    public func getPendingRequests() throws -> [(AuthRequest, VerifyContext?)] {
        let pendingRequests: [AuthRequest] = rpcHistory.getPending()
            .filter {$0.request.method == "wc_authRequest"}
            .compactMap {
                guard let params = try? $0.request.params?.get(Auth_RequestParams.self) else { return nil }
                return AuthRequest(id: $0.request.id!, topic: $0.topic, payload: params.payloadParams, requester: params.requester.metadata)
            }
        
        return pendingRequests.map { ($0, try? verifyContextStore.get(key: $0.id.string)) }
    }
}
