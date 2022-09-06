import Foundation
import JSONRPC

public struct RequestSubscriptionPayload<Request: Codable>: Codable, SubscriptionPayload {
    public let id: RPCID
    public let topic: String
    public let request: Request

    public init(id: RPCID, topic: String, request: Request) {
        self.id = id
        self.topic = topic
        self.request = request
    }
}
