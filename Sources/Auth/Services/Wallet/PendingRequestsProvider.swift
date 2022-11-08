import Foundation

class PendingRequestsProvider {
    private let rpcHistory: RPCHistory

    init(rpcHistory: RPCHistory) {
        self.rpcHistory = rpcHistory
    }

    public func getPendingRequests(account: Account) throws -> [AuthRequest] {
        let pendingRequests: [AuthRequest] = rpcHistory.getPending()
            .filter {$0.request.method == "wc_authRequest"}
            .compactMap {
                guard let params = try? $0.request.params?.get(AuthRequestParams.self),
                      let message = SIWEMessageFormatter().formatMessage(from: params.payloadParams, address: account.address) else {return nil}
                return AuthRequest(id: $0.request.id!, message: message)
            }
        return pendingRequests
    }
}
