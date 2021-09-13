
import Foundation
@testable import WalletConnect

class MockedRelay: Relaying {
    var didCallSubscribe = false
    var didCallUnsubscribe = false
    func publish(topic: String, payload: Encodable, completion: @escaping ((Result<Void, Error>) -> ())) throws -> Int64 {
        fatalError()
    }
    
    func subscribe(topic: String, completion: @escaping ((Result<String, Error>) -> ())) throws -> Int64 {
        didCallSubscribe = true
        completion(.success(""))
        return 0
    }
    
    func unsubscribe(topic: String, id: String, completion: @escaping ((Result<Void, Error>) -> ())) throws -> Int64 {
        didCallUnsubscribe = true
        completion(.success(()))
        return 0
    }
}
