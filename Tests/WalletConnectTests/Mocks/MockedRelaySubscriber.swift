
import Foundation
@testable import WalletConnect

class MockedRelaySubscriber: RelaySubscriber {
    var subscriptionIds = [String]()
    var pendingRequestsIds = [Int64]()
    var jsonRpcRequest: ClientSynchJSONRPC? = nil
    var requestAcknowledged: Bool = false
    var subscriptionAcknowledged: Bool = false

    func onRequest(_ jsonRpcRequest: ClientSynchJSONRPC) {
        self.jsonRpcRequest = jsonRpcRequest
    }
    
    func onResponse(requestId: Int64, responseType: JSONRPCResponseType) {
        switch responseType {
        case .requestAcknowledge:
            requestAcknowledged = true
        case .subscriptionAcknowledge(_):
            subscriptionAcknowledged = true
        }
    }
    
    func isSubscribing(for subscriptionId: String) -> Bool {
        return subscriptionIds.contains(subscriptionId)
    }
    
    func hasPendingRequest(id: Int64) -> Bool {
        return pendingRequestsIds.contains(id)
    }
    
    func set(pendingRequestId: Int64) {
        pendingRequestsIds.append(pendingRequestId)
    }
}
