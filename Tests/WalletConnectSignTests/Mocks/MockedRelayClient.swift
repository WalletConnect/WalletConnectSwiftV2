import Combine
import Foundation
@testable import WalletConnectRelay
@testable import WalletConnectSign

class MockedRelayClient: NetworkRelaying {
    func subscribe(topic: String) async throws {}

    var socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    func publish(topic: String, payload: String, tag: Int, prompt: Bool) async throws {
        self.prompt = prompt
    }

    var onMessage: ((String, String) -> Void)?
    var error: Error?
    var prompt = false
    func publish(topic: String, payload: String, tag: Int, prompt: Bool, onNetworkAcknowledge: @escaping ((Error?) -> Void)) {//}-> Int64 {
        self.prompt = prompt
        onNetworkAcknowledge(error)
//        return 0
    }

    func subscribe(topic: String, completion: @escaping (Error?) -> Void) {
    }

    func unsubscribe(topic: String, completion: @escaping ((Error?) -> Void)) -> Int64? {
        return 0
    }
    func connect() {
    }

    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {
    }

}
