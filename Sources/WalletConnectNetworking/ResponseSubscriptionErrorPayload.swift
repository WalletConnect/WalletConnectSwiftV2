import Foundation
import JSONRPC

public struct ResponseSubscriptionErrorPayload<Request: Codable>: Codable, SubscriptionPayload {
    public let id: RPCID
    public let topic: String
    public let request: Request
    public let error: JSONRPCError

    public init(id: RPCID, topic: String, request: Request, error: JSONRPCError) {
        self.id = id
        self.topic = topic
        self.request = request
        self.error = error
    }
}
