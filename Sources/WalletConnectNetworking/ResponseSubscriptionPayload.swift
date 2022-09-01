import Foundation
import JSONRPC

public struct ResponseSubscriptionPayload: Codable, Equatable {
    public let topic: String
    public let response: RPCResponse

    public init(topic: String, response: RPCResponse) {
        self.topic = topic
        self.response = response
    }
}
