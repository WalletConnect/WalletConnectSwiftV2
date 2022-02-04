
import Foundation

class ManualSocketConnectionHandler: SocketConnectionHandler {
    var socket: WebSocketSessionProtocol
    
    init(socket: WebSocketSessionProtocol) {
        self.socket = socket
    }

    func handleConnect() throws {
        socket.connect()
    }
    
    func handleDisconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        socket.disconnect(with: closeCode)
    }
    
    func handleNetworkUnsatisfied() {
        return
    }
    
    func handleNetworkSatisfied() {
        return
    }

}
