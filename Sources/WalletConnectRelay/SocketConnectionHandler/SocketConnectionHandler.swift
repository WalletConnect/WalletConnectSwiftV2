import Foundation

protocol SocketConnectionHandler {
    /// handles connection request from the sdk consumes
    func handleConnect() throws
    /// handles connection request from sdk's internal function
    func handleInternalConnect() async throws
    func handleDisconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws
    func handleDisconnection() async
}
