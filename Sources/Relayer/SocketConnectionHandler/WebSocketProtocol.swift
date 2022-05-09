
import Starscream

extension WebSocket: WebSocketProtocol{}

protocol WebSocketProtocol {
    var isConnected: Bool {get}
    var onConnect: (() -> ())? { get set }
    var onDisconnect: ((Error?) -> ())? { get set }
    var onText: ((String)->())? { get set }
    func write(string: String, completion: (() -> ())?)
}
