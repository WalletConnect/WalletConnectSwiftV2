import Foundation
import JSONRPC

struct RequestSubscriptionPayload: Codable {
    let id: Int64
    let request: RPCRequest
}
