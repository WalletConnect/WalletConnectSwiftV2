import Foundation

public struct ResponseSubscriptionPayload<Request: Codable, Response: Codable>: SubscriptionPayload {
    public let id: RPCID
    public let topic: String
    public let request: Request
    public let response: Response
    public let publishedAt: Date
    public let derivedTopic: String?

    public init(id: RPCID, topic: String, request: Request, response: Response, publishedAt: Date, derivedTopic: String?) {
        self.id = id
        self.topic = topic
        self.request = request
        self.response = response
        self.publishedAt = publishedAt
        self.derivedTopic = derivedTopic
    }
}
