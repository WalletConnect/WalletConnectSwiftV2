
import Foundation
@testable import WalletConnect

class MockedRelaySubscriber: RelaySubscriber {
    var subscriptionIds = [String]()
    var pendingRequestsIds = [Int64]()
    var notified = false
    
    func onRequest(_ jsonRpcRequest: ClientSynchJSONRPC) {
        notified = true
    }
    
    func onResponse(requestId: Int64, responseType: Relay.JSONRPCResponseType) {
        <#code#>
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
