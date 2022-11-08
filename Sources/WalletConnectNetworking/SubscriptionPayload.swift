import Foundation

public protocol SubscriptionPayload {
    var id: RPCID { get }
    var topic: String { get }
}
