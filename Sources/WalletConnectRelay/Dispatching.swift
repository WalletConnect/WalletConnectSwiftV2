import Foundation
import WalletConnectUtils
import Starscream

protocol Dispatching {
    var onConnect: (()->())? {get set}
    var onDisconnect: (()->())? {get set}
    var onMessage: ((String) -> ())? {get set}
    func send(_ string: String) async throws
    func send(_ string: String, completion: @escaping (Error?)->())
    func connect() throws
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws
}

final class Dispatcher: NSObject, Dispatching {
    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
    var onMessage: ((String) -> ())?
    private var textFramesQueue = Queue<String>()
    private let logger: ConsoleLogging
    var socket: WebSocketProtocol
    var socketConnectionHandler: SocketConnectionHandler
    
    init(socket: WebSocketProtocol,
         socketConnectionHandler: SocketConnectionHandler,
         logger: ConsoleLogging) {
        self.socket = socket
        self.logger = logger
        self.socketConnectionHandler = socketConnectionHandler
        super.init()
        setUpWebSocketSession()
        setUpSocketConnectionObserving()
    }

    func send(_ string: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            if socket.isConnected {
                socket.write(string: string) {
                    continuation.resume(returning: ())
                }
            } else {
                continuation.resume(throwing: NetworkError.webSocketNotConnected)
            }
        }
    }
    
    func send(_ string: String, completion: @escaping (Error?) -> Void) {
        //TODO - add policy for retry and "single try"
        if socket.isConnected {
            self.socket.write(string: string) {
                completion(nil)
            }
            //TODO - enqueue     if fails
        } else {
            completion(NetworkError.webSocketNotConnected)
//            textFramesQueue.enqueue(string)
        }
    }
    
    func connect() throws {
        try socketConnectionHandler.handleConnect()
    }
    
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        try socketConnectionHandler.handleDisconnect(closeCode: closeCode)
    }
    
    private func setUpWebSocketSession() {
        socket.onText = { [weak self] in
            self?.onMessage?($0)
        }
    }
    
    private func setUpSocketConnectionObserving() {
        socket.onConnect = { [weak self] in
            self?.dequeuePendingTextFrames()
            self?.onConnect?()
        }
        socket.onDisconnect = { [weak self] error in
            self?.onDisconnect?()
        }
    }
    
    private func dequeuePendingTextFrames() {
        while let frame = textFramesQueue.dequeue() {
            send(frame) { error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
}
