import Foundation
import JSONRPC

struct ResponseSubscriptionPayload: Codable, Equatable {
    let topic: String
    let response: RPCResponse
}
