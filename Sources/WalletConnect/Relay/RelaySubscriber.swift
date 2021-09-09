
import Foundation

protocol RelaySubscriber: class {
    func onRequest(_ jsonRpcRequest: ClientSynchJSONRPC)
    func onResponse(requestId: Int64, responseType: JSONRPCResponseType)
    func isSubscribing(for subscriptionId: String) -> Bool
    func hasPendingRequest(id: Int64) -> Bool
    func set(pendingRequestId: Int64)
}
