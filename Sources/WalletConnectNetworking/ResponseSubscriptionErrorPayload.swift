import Foundation
import JSONRPC

public struct ResponseSubscriptionErrorPayload {
    public let id: RPCID
    public let error: JSONRPCError

    public init(id: RPCID, error: JSONRPCError) {
        self.id = id
        self.error = error
    }
}
