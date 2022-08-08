import Foundation
import JSONRPC

struct RequestSubscriptionPayload: Codable, Equatable {
    let topic: String
    let request: RPCRequest
}
