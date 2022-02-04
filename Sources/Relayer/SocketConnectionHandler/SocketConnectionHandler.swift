
import Foundation

protocol SocketConnectionHandler {
    var socket: WebSocketSessionProtocol {get}
    func handleConnect() throws
    func handleDisconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws
}
