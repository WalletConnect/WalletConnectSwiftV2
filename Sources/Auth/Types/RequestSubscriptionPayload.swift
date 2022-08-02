import Foundation
import JSONRPC

struct RequestSubscriptionPayload: Codable {
    let id: String
    let request: RPCRequest
}
