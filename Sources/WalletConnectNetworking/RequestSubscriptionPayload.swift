import Foundation

public struct RequestSubscriptionPayload<Request: Codable>: Codable, SubscriptionPayload {
    public let id: RPCID
    public let topic: String
    public let request: Request
    public let rawRequest: String?
    public let publishedAt: Date
    public let derivedTopic: String?

    public init(id: RPCID, topic: String, request: Request, rawRequest: String?, publishedAt: Date, derivedTopic: String?) {
        self.id = id
        self.topic = topic
        self.request = request
        self.rawRequest = rawRequest
        self.publishedAt = publishedAt
        self.derivedTopic = derivedTopic
    }
}
