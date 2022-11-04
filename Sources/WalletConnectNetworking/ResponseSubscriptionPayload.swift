import Foundation

public struct ResponseSubscriptionPayload<Request: Codable, Response: Codable>: SubscriptionPayload {
    public let id: RPCID
    public let topic: String
    public let request: Request
    public let response: Response

    public init(id: RPCID, topic: String, request: Request, response: Response) {
        self.id = id
        self.topic = topic
        self.request = request
        self.response = response
    }
}
