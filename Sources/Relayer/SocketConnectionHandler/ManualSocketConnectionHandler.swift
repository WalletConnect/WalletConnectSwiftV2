
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
