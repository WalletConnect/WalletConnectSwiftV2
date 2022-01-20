
import Foundation
import Relayer

extension WakuNetworkRelay: NetworkRelaying {}

protocol NetworkRelaying {
    var onConnect: (()->())? {get set}
    var onMessage: ((_ topic: String, _ message: String) -> ())? {get set}
    func connect()
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode)
    /// - returns: request id
    @discardableResult func publish(topic: String, payload: String, completion: @escaping ((Error?)->())) -> Int64
    /// - returns: request id
    @discardableResult func subscribe(topic: String, completion: @escaping (Error?)->()) -> Int64
    /// - returns: request id
    @discardableResult func unsubscribe(topic: String, completion: @escaping ((Error?)->())) -> Int64?
}
