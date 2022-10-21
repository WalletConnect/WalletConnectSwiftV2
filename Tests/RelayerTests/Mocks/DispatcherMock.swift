import Foundation
import JSONRPC
import Combine
@testable import WalletConnectRelay

class DispatcherMock: Dispatching {
    private var publishers = Set<AnyCancellable>()
    private let socketConnectionStatusPublisherSubject = CurrentValueSubject<SocketConnectionStatus, Never>(.disconnected)
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        return socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    var sent = false
    var lastMessage: String = ""
    var onMessage: ((String) -> Void)?

    func protectedSend(_ string: String, completion: @escaping (Error?) -> Void) {
        send(string, completion: completion)
    }

    func protectedSend(_ string: String) async throws {
        try await send(string)
    }

    func connect() {
        socketConnectionStatusPublisherSubject.send(.connected)
    }

    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {
        socketConnectionStatusPublisherSubject.send(.disconnected)
    }

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
