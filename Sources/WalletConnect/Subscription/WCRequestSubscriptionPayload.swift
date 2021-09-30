
import Foundation

struct WCRequestSubscriptionPayload {
    let topic: String
    let subscriptionId: String
    let clientSynchJsonRpc: ClientSynchJSONRPC
}

struct WCResponseSubscriptionPayload {
    let topic: String
    let subscriptionId: String
    let response: JSONRPCResponse<String>
}
