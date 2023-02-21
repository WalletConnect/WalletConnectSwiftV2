import Foundation

public struct RequestSubscriptionPayload<Request: Codable>: Codable, SubscriptionPayload {
    public let id: RPCID
    public let topic: String
    public let request: Request
    public let publishedAt: Date

    public init(id: RPCID, topic: String, request: Request, publishedAt: Date) {
        self.id = id
        self.topic = topic
        self.request = request
        self.publishedAt = publishedAt
    }
}
