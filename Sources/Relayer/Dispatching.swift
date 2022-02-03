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
    var socket: WebSocketSessionProtocol
    var socketConnectionObserver: SocketConnectionObserving
    var socketConnectionHandler: SocketConnectionHandler
    
    init(networkMonitor: NetworkMonitoring = NetworkMonitor(),
         socket: WebSocketSessionProtocol,
         socketConnectionObserver: SocketConnectionObserving,
         socketConnectionHandler: SocketConnectionHandler) {
        self.networkMonitor = networkMonitor
        self.socket = socket
        self.socketConnectionObserver = socketConnectionObserver
        self.socketConnectionHandler = socketConnectionHandler
        super.init()
        setUpWebSocketSession()
        setUpSocketConnectionObserving()
        setUpNetworkMonitoring()
        socket.connect()
    }

    func send(_ string: String, completion: @escaping (Error?) -> Void) {
        if socket.isConnected {
            self.socket.send(string, completionHandler: completion)
            //TODO - enqueue     if fails
        } else {
            textFramesQueue.enqueue(string)
        }
    }
    
    func connect() {
        //todo handle error
        try! socketConnectionHandler.handleConnect()
    }
    
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {
        //todo handle error
        try! socketConnectionHandler.handleDisconnect()
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
            self?.socketConnectionHandler.handleNetworkSatisfied()
        }
        networkMonitor.onUnsatisfied = { [weak self] in
            self?.socketConnectionHandler.handleNetworkUnsatisfied()
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


