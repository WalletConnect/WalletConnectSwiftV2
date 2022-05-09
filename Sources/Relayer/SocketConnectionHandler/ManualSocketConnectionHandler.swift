
import Foundation

class ManualSocketConnectionHandler: SocketConnectionHandler {
    var socket: WebSocketConnecting
    
    init(socket: WebSocketConnecting) {
        self.socket = socket
    }

    func handleConnect() throws {
        socket.connect()
    }
    
    func handleDisconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        socket.disconnect()
    }
}
protocol WebSocketConnecting {
    var isConnected: Bool {get}
    func connect()
    func disconnect()
}

import Starscream
extension WebSocket: WebSocketConnecting{}
extension WebSocket: WebSocketProtocol{}
protocol WebSocketProtocol {
    var isConnected: Bool {get}
    var onConnect: (() -> ())? { get set }
    var onDisconnect: ((Error?) -> ())? { get set }
    var onText: ((String)->())? { get set }
    func write(string: String, completion: (() -> ())?)
}
