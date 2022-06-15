// 

import Foundation
@testable import WalletConnectRelay

class DispatcherMock: Dispatching {
    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
    var onMessage: ((String) -> ())?
    var sent = false
    func send(_ string: String, completion: @escaping (Error?) -> ()) {
        sent = true
    }
    func send(_ string: String) async throws {
        send(string, completion: { _ in })
    }
    func connect() {}
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {}
}
