import Starscream

extension WebSocket: WebSocketProtocol {}

protocol WebSocketProtocol {
    var isConnected: Bool {get}
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: ((Error?) -> Void)? { get set }
    var onText: ((String) -> Void)? { get set }
    func write(string: String, completion: (() -> Void)?)
}
