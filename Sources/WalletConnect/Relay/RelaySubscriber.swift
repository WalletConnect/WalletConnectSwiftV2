
import Foundation

protocol RelaySubscriber: class {
    func onRequest(_ jsonRpcRequest: ClientSynchJSONRPC)
    func onResponse(requestId: Int64, responseType: Relay.JSONRPCResponseType)
    func isSubscribing(for subscriptionId: String) -> Bool
    func hasPendingRequest(id: Int64) -> Bool
    func set(pendingRequestId: Int64)
}

extension Relay {
    enum JSONRPCResponseType {
        case requestAcknowledge
        case subscriptionAcknowledge(String)
    }
}
