import Foundation
import WalletConnectUtils

protocol Dispatching {
    var onConnect: (()->())? {get set}
    var onDisconnect: (()->())? {get set}
    var onMessage: ((String) -> ())? {get set}
    func send(_ string: String, completion: @escaping (Error?)->())
    func connect()
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode)
}

final class Dispatcher: NSObject, Dispatching {
    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
    var onMessage: ((String) -> ())?
    private var textFramesQueue = Queue<String>()
    private var networkMonitor: NetworkMonitoring
    private let url: URL
    var socket: WebSocketSessionProtocol
    var socketConnectionObserver: SocketConnectionObserving
    
    init(url: URL,
         networkMonitor: NetworkMonitoring = NetworkMonitor(),
         socket: WebSocketSessionProtocol,
         socketConnectionObserver: SocketConnectionObserving) {
        self.url = url
        self.networkMonitor = networkMonitor
        self.socket = socket
        self.socketConnectionObserver = socketConnectionObserver
        super.init()
        setUpWebSocketSession()
        setUpSocketConnectionObserving()
        setUpNetworkMonitoring()
        socket.connect(on: url)
    }

    func send(_ string: String, completion: @escaping (Error?) -> Void) {
        if socket.isConnected {
            self.socket.send(string, completionHandler: completion)
        } else {
            textFramesQueue.enqueue(string)
        }
    }
    
    func connect() {
        if !socket.isConnected {
            socket.connect(on: url)
        }
    }
    
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {
        socket.disconnect(with: closeCode)
        onDisconnect?()
    }
    
    private func setUpWebSocketSession() {
        socket.onMessageReceived = { [weak self] in
            self?.onMessage?($0)
        }
        socket.onMessageError = { error in
            print(error)
        }
    }
    
    private func setUpSocketConnectionObserving() {
        socketConnectionObserver.onConnect = { [weak self] in
            self?.dequeuePendingTextFrames()
            self?.onConnect?()
        }
        socketConnectionObserver.onDisconnect = { [weak self] in
            self?.onDisconnect?()
        }
    }
    
    private func setUpNetworkMonitoring() {
        networkMonitor.onSatisfied = { [weak self] in
            self?.connect()
        }
        networkMonitor.onUnsatisfied = { [weak self] in
            self?.disconnect(closeCode: .goingAway)
        }
        networkMonitor.startMonitoring()
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

