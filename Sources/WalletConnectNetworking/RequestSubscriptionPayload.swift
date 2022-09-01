import Foundation
import JSONRPC

public struct RequestSubscriptionPayload: Codable, Equatable {
    public let topic: String
    public let request: RPCRequest

    public init(topic: String, request: RPCRequest) {
        self.topic = topic
        self.request = request
    }
}
