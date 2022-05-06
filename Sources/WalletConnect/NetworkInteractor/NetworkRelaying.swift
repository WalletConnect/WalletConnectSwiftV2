
import Foundation
import Relayer
import Combine

extension Relayer: NetworkRelaying {}

protocol NetworkRelaying {
    var onMessage: ((_ topic: String, _ message: String) -> ())? {get set}
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
    func connect() throws
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws
    func publish(topic: String, payload: String, prompt: Bool) async throws
    /// - returns: request id
    @discardableResult func publish(topic: String, payload: String, prompt: Bool, onNetworkAcknowledge: @escaping ((Error?)->())) -> Int64
    /// - returns: request id
    @discardableResult func subscribe(topic: String, completion: @escaping (Error?)->()) -> Int64
    /// - returns: request id
    @discardableResult func unsubscribe(topic: String, completion: @escaping ((Error?)->())) -> Int64?
}
