import Foundation
import JSONRPC

public struct ResponseSubscriptionPayload<Request: Codable, Response: Codable> {
    public let topic: String
    public let request: Request
    public let response: Response

    public init(topic: String, request: Request, response: Response) {
        self.topic = topic
        self.request = request
        self.response = response
    }
}
