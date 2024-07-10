import Foundation

class ManualSocketConnectionHandler: SocketConnectionHandler {

    private let socket: WebSocketConnecting
    private let logger: ConsoleLogging
    private let defaultTimeout: Int = 60
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.manual_socket_connection", attributes: .concurrent)

    init(
        socket: WebSocketConnecting,
        logger: ConsoleLogging) {
            self.socket = socket
            self.logger = logger
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
                self.logger.debug("Connection timed out, will rety to connect...")
                retryToConnect()
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

    private func retryToConnect() {
        if !socket.isConnected {
            socket.connect()
        }
    }
}
