import Foundation
import WalletConnectUtils

protocol Dispatching {
    var onConnect: (() -> Void)? {get set}
    var onDisconnect: (() -> Void)? {get set}
    var onMessage: ((String) -> Void)? {get set}
    func send(_ string: String, completion: @escaping (Error?) -> Void)
    func connect() throws
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws
}

final class Dispatcher: NSObject, Dispatching {
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onMessage: ((String) -> Void)?
    private var textFramesQueue = Queue<String>()
    private let logger: ConsoleLogging
    var socket: WebSocketConnecting
    var socketConnectionHandler: SocketConnectionHandler

    init(socket: WebSocketConnecting,
         socketConnectionHandler: SocketConnectionHandler,
         logger: ConsoleLogging) {
        self.socket = socket
        self.logger = logger
        self.socketConnectionHandler = socketConnectionHandler
        super.init()
        setUpWebSocketSession()
        setUpSocketConnectionObserving()
    }

    func send(_ string: String, completion: @escaping (Error?) -> Void) {
        if socket.isConnected {
            self.socket.write(string: string) {
                completion(nil)
            }
        } else {
            completion(NetworkError.webSocketNotConnected)
        }
    }

    func connect() throws {
        try socketConnectionHandler.handleConnect()
    }

    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        try socketConnectionHandler.handleDisconnect(closeCode: closeCode)
    }

    private func setUpWebSocketSession() {
        socket.onText = { [unowned self] in
            self.onMessage?($0)
        }
    }

    private func setUpSocketConnectionObserving() {
        socket.onConnect = { [unowned self] in
            self.onConnect?()
        }
        socket.onDisconnect = { [unowned self] _ in
            self.onDisconnect?()
        }
    }
}
