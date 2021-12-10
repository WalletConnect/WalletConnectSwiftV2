// 

import Foundation
@testable import Iridium

class MockedJSONRPCTransport: JSONRPCTransporting {
    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
    var onMessage: ((String) -> ())?
    var sent = false
    func send(_ string: String, completion: @escaping (Error?) -> ()) {
        sent = true
    }
    func connect() {}
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {}
}
