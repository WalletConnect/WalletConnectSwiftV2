// 

import Foundation
@testable import WalletConnectRelay

class DispatcherMock: Dispatching {
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onMessage: ((String) -> Void)?
    var sent = false
    func send(_ string: String, completion: @escaping (Error?) -> Void) {
        sent = true
    }
    func send(_ string: String) async throws {
        send(string, completion: { _ in })
    }
    func connect() {}
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {}
}
