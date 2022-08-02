import Foundation
import WalletConnectRelay
import Combine

extension RelayClient: NetworkRelaying {}

protocol NetworkRelaying {
    var onMessage: ((_ topic: String, _ message: String) -> Void)? {get set}
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
    func connect() throws
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws
    func publish(topic: String, payload: String, tag: Int, prompt: Bool) async throws
    /// - returns: request id
    func publish(topic: String, payload: String, tag: Int, prompt: Bool, onNetworkAcknowledge: @escaping ((Error?) -> Void))
    func subscribe(topic: String) async throws
    /// - returns: request id
    func unsubscribe(topic: String, completion: @escaping ((Error?) -> Void))
}
