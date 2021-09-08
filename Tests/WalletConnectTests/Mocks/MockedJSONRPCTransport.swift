// 

import Foundation
@testable import WalletConnect

class MockedJSONRPCTransport: JSONRPCTransporting {
    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
    var onMessage: ((String) -> ())?
    var send = false
    func send(_ string: String, completion: @escaping (Error?) -> ()) {
        send = true
    }
    
    func disconnect() {}
}
