
import Foundation
import Combine

protocol SocketStatusProviding {
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
}

class SocketStatusProvider: SocketStatusProviding {
    private var socket: WebSocketConnecting
    private let logger: ConsoleLogging
    private let socketConnectionStatusPublisherSubject = CurrentValueSubject<SocketConnectionStatus, Never>(.disconnected)

    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    init(socket: WebSocketConnecting,
         logger: ConsoleLogging) {
        self.socket = socket
        self.logger = logger
        setUpSocketConnectionObserving()
    }

    private func setUpSocketConnectionObserving() {
        socket.onConnect = { [unowned self] in
            self.socketConnectionStatusPublisherSubject.send(.connected)
        }
        socket.onDisconnect = { [unowned self] error in
            logger.debug("Socket disconnected with error: \(error?.localizedDescription ?? "Unknown error")")
            self.socketConnectionStatusPublisherSubject.send(.disconnected)
        }
    }
}
