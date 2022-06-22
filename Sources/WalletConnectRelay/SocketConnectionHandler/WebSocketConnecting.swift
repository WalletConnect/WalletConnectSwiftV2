import Foundation

public protocol WebSocketConnecting {
    static func instance(with url: URL) -> WebSocketConnecting

    var isConnected: Bool { get }
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: ((Error?) -> Void)? { get set }
    var onText: ((String) -> Void)? { get set }

    func connect()
    func disconnect()
    func write(string: String, completion: (() -> Void)?)
}
