import Foundation
import Starscream

public protocol WebSocketConnecting: AnyObject {
    var isConnected: Bool { get }
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: ((Error?) -> Void)? { get set }
    var onText: ((String) -> Void)? { get set }

    func connect()
    func disconnect()
    func write(string: String, completion: (() -> Void)?)
}

public protocol WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting
}

extension WebSocket: WebSocketConnecting {}

public struct SocketFactory: WebSocketFactory {

    public init() {}

    public func create(with url: URL) -> WebSocketConnecting {
        var request = URLRequest(url: url)
        request.addValue(EnvironmentInfo.userAgent, forHTTPHeaderField: "User-Agent")
        return WebSocket(request: request)
    }
}
