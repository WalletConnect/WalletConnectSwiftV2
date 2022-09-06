import Foundation
import JSONRPC

public protocol SubscriptionPayload {
    var id: RPCID { get }
    var topic: String { get }
}
