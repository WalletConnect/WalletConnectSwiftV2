
import Foundation
@testable import WalletConnect

class MockedNetworkRelayer: NetworkRelaying {
    func publish(topic: String, payload: String, prompt: Bool) async throws {
        self.prompt = prompt

    }
    
    var onConnect: (() -> ())?
    var onMessage: ((String, String) -> ())?
    var error: Error?
    var prompt = false
    func publish(topic: String, payload: String, prompt: Bool, onNetworkAcknowledge: @escaping ((Error?) -> ())) -> Int64 {
        self.prompt = prompt
        onNetworkAcknowledge(error)
        return 0
    }
    
    func subscribe(topic: String, completion: @escaping (Error?) -> ()) -> Int64 {
        return 0
    }
    
    func unsubscribe(topic: String, completion: @escaping ((Error?) -> ())) -> Int64? {
        return 0
    }
    func connect() {
    }
    
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {
    }
    
}
