
import Foundation
import WalletConnectRelay
import Combine

extension RelayClient: NetworkRelaying {}

protocol NetworkRelaying {
    var onMessage: ((_ topic: String, _ message: String) -> ())? {get set}
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
    func connect() throws
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws
    func publish(topic: String, payload: String, prompt: Bool) async throws
    /// - returns: request id
    @discardableResult func publish(topic: String, payload: String, prompt: Bool, onNetworkAcknowledge: @escaping ((Error?)->())) -> Int64
    func subscribe(topic: String, completion: @escaping (Error?)->())
    func subscribe(topic: String) async throws 
    /// - returns: request id
    @discardableResult func unsubscribe(topic: String, completion: @escaping ((Error?)->())) -> Int64?
}
