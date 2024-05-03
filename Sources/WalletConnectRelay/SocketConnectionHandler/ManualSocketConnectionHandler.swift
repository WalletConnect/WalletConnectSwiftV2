import Foundation

class ManualSocketConnectionHandler: SocketConnectionHandler {

    private let socket: WebSocketConnecting
    private let logger: ConsoleLogging
    private let defaultTimeout: Int = 5
    private var socketUrlFallbackHandler: SocketUrlFallbackHandler
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.manual_socket_connection", attributes: .concurrent)

    init(
        socket: WebSocketConnecting,
        logger: ConsoleLogging,
        socketUrlFallbackHandler: SocketUrlFallbackHandler) {
            self.socket = socket
            self.logger = logger
            self.socketUrlFallbackHandler = socketUrlFallbackHandler

            socketUrlFallbackHandler.onTryReconnect = { [unowned self] in
                Task(priority: .high) {
                    await tryReconect()
                }
            }
        }

    func handleConnect() throws {
        socket.connect()
        // Start a timer for the fallback mechanism
        let timer = DispatchSource.makeTimerSource(queue: concurrentQueue)
        timer.schedule(deadline: .now() + .seconds(defaultTimeout))
        timer.setEventHandler { [weak self] in
            guard let self = self else {
                timer.cancel()
                return
            }
            if !self.socket.isConnected {
                self.logger.debug("Connection timed out, initiating fallback...")
                self.socketUrlFallbackHandler.handleFallbackIfNeeded(error: .connectionFailed)
            }
            timer.cancel()
        }
        timer.resume()
    }

    func handleDisconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        socket.disconnect()
    }

    func handleDisconnection() async {
        // No operation
        // ManualSocketConnectionHandler does not support reconnection logic
    }

    func tryReconect() async {
        if !socket.isConnected {
            socket.connect()
        }
    }
}
