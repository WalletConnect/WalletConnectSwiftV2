// 

import Foundation
@testable import WalletConnect_Swift


class MockedRelaySubscriber: RelaySubscriber {
    var topic: String = ""
    var notified = false
    func update(with jsonRpcRequest: ClientSynchJSONRPC) {
        notified = true
    }
}
