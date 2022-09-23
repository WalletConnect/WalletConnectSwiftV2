import Combine
import Foundation
@testable import WalletConnectRelay
@testable import WalletConnectSign

class MockedRelayClient: NetworkRelaying {

    var messagePublisherSubject = PassthroughSubject<(topic: String, message: String), Never>()
    var messagePublisher: AnyPublisher<(topic: String, message: String), Never> {
        messagePublisherSubject.eraseToAnyPublisher()
    }

    var socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    var error: Error?
    var prompt = false

    func publish(topic: String, payload: String, tag: Int, prompt: Bool) async throws {
        self.prompt = prompt
    }

    func publish(topic: String, payload: String, tag: Int, prompt: Bool, onNetworkAcknowledge: @escaping ((Error?) -> Void)) {
        self.prompt = prompt
        onNetworkAcknowledge(error)
    }

    func subscribe(topic: String) async throws {}

    func subscribe(topic: String, completion: @escaping (Error?) -> Void) {
    }

    func unsubscribe(topic: String, completion: @escaping ((Error?) -> Void)) {
    }

    func connect() {
    }

    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {
    }

}
