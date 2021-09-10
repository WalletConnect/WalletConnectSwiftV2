// 

import Foundation
@testable import WalletConnect

class MockedJSONRPCTransport: JSONRPCTransporting {
    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
    var onMessage: ((String) -> ())?
    var sent = false
    func send(_ string: String, completion: @escaping (Error?) -> ()) {
        sent = true
    }
    
    func disconnect() {}
}
