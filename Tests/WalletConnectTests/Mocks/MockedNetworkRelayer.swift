import Combine
import Foundation
@testable import Relayer
@testable import WalletConnect

class MockedNetworkRelayer: NetworkRelaying {
    func subscribe(topic: String) async throws {}
    
    var socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }
    
    func publish(topic: String, payload: String, prompt: Bool) async throws {
        self.prompt = prompt
    }
    
    var onMessage: ((String, String) -> ())?
    var error: Error?
    var prompt = false
    func publish(topic: String, payload: String, prompt: Bool, onNetworkAcknowledge: @escaping ((Error?) -> ())) -> Int64 {
        self.prompt = prompt
        onNetworkAcknowledge(error)
        return 0
    }
    
    func subscribe(topic: String, completion: @escaping (Error?) -> ()) {
    }
    
    func unsubscribe(topic: String, completion: @escaping ((Error?) -> ())) -> Int64? {
        return 0
    }
    func connect() {
    }
    
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {
    }
    
}
