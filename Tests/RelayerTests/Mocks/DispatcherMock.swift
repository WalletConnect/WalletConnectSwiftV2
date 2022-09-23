import Foundation
import JSONRPC
@testable import WalletConnectRelay

class DispatcherMock: Dispatching {

    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onMessage: ((String) -> Void)?

    func connect() {}
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {}

    var sent = false
    var lastMessage: String = ""

    func send(_ string: String, completion: @escaping (Error?) -> Void) {
        sent = true
        lastMessage = string
    }
    func send(_ string: String) async throws {
        send(string, completion: { _ in })
    }
}

extension DispatcherMock {

    func getLastRequestSent() -> RPCRequest {
        let data = lastMessage.data(using: .utf8)!
        return try! JSONDecoder().decode(RPCRequest.self, from: data)
    }
}
