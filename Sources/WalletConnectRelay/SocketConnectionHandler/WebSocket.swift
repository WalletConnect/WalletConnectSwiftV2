import Foundation

public protocol WebSocketConnecting: AnyObject {
    var isConnected: Bool { get }
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: ((Error?) -> Void)? { get set }
    var receive: ((String) -> Void)? { get set }
    var request: URLRequest { get set }
    
    func connect()
    func disconnect()
    func reconnect()
    func send(message: String, completion: (() -> Void)?)
}

public protocol WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting
}
