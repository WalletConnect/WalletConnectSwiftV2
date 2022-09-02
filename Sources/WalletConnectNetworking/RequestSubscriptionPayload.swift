import Foundation
import JSONRPC

public struct RequestSubscriptionPayload<Request: Codable> {
    public let topic: String
    public let request: Request

    public init(topic: String, request: Request) {
        self.topic = topic
        self.request = request
    }
}
