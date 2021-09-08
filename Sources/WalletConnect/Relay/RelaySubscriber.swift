
import Foundation

protocol RelaySubscriber: class {
    func onRequest(_ jsonRpcRequest: ClientSynchJSONRPC)
    func onResponse(requestId: String, responseType: Relay.SubscriberResponseType)
    func isSubscribing(for subscriptionId: String) -> Bool
    func hasPendingRequest(id: Int64) -> Bool
    func set(pendingRequestId: Int64)
}

extension Relay {
    enum SubscriberResponseType {
        case requestAcknowledge
        case error(Error)
        case subscriptionAcknowledge(String)
    }
}
