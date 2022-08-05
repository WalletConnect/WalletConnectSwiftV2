import Foundation
import JSONRPC

struct RequestSubscriptionPayload: Codable {
    let topic: String
    let request: RPCRequest
}
