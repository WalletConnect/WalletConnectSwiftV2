import Foundation

protocol SocketConnectionHandler {
    func handleConnect() throws
    func handleDisconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws
    func handleDisconnection() async
}
