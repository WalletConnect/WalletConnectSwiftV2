import Foundation

class SocketUrlFallbackHandler {
    private let relayUrlFactory: RelayUrlFactory
    private var logger: ConsoleLogging
    private var socket: WebSocketConnecting
    private let networkMonitor: NetworkMonitoring
    var onTryReconnect: (()->())?

    init(
        relayUrlFactory: RelayUrlFactory,
        logger: ConsoleLogging,
        socket: WebSocketConnecting,
        networkMonitor: NetworkMonitoring) {
            self.relayUrlFactory = relayUrlFactory
            self.logger = logger
            self.socket = socket
            self.networkMonitor = networkMonitor
        }

    func handleFallbackIfNeeded(error: NetworkError) {
        if error == .connectionFailed && socket.request.url?.host == NetworkConstants.defaultUrl {
            logger.debug("[WebSocket] - Fallback to \(NetworkConstants.fallbackUrl)")
            relayUrlFactory.setFallback()
            socket.request.url = relayUrlFactory.create()
            onTryReconnect?()
        }
    }
}
