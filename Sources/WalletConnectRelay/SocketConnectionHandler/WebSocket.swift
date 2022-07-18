import Foundation

public protocol WebSocketConnecting: AnyObject {
    var isConnected: Bool { get }
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: ((Error?) -> Void)? { get set }
    var onText: ((String) -> Void)? { get set }
    var request: URLRequest { get set }
    func connect()
    func disconnect()
    func write(string: String, completion: (() -> Void)?)
}

public protocol WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting
}
