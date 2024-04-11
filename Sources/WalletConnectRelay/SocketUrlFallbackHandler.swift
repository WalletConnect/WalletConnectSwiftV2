import Foundation

class SocketUrlFallbackHandler {
    private let relayUrlFactory: RelayUrlFactory
    private var logger: ConsoleLogging
    private var socketConnectionHandler: SocketConnectionHandler
    private var socket: WebSocketConnecting
    private let networkMonitor: NetworkMonitoring

    init(relayUrlFactory: RelayUrlFactory,
         logger: ConsoleLogging,
         socketConnectionHandler: SocketConnectionHandler,
         socket: WebSocketConnecting,
         networkMonitor: NetworkMonitoring) {
        self.relayUrlFactory = relayUrlFactory
        self.logger = logger
        self.socketConnectionHandler = socketConnectionHandler
        self.socket = socket
        self.networkMonitor = networkMonitor
    }

    func handleFallbackIfNeeded(error: NetworkError) {
        if error == .connectionFailed && socket.request.url?.host == NetworkConstants.defaultUrl {
            logger.debug("[WebSocket] - Fallback to \(NetworkConstants.fallbackUrl)")
            relayUrlFactory.setFallback()
            socket.request.url = relayUrlFactory.create()
            Task(priority: .high) {
                await self.socketConnectionHandler.tryReconect()
            }
        }
    }
}
