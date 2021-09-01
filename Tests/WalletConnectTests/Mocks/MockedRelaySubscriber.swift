// 

import Foundation
@testable import WalletConnect


class MockedRelaySubscriber: RelaySubscriber {
    var topic: String = ""
    var notified = false
    func update(with jsonRpcRequest: ClientSynchJSONRPC) {
        notified = true
    }
}
