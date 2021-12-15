import Foundation
import Network

protocol JSONRPCTransporting {
    var onConnect: (()->())? {get set}
    var onDisconnect: (()->())? {get set}
    var onMessage: ((String) -> ())? {get set}
    func send(_ string: String, completion: @escaping (Error?)->())
    func connect()
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode)
}



final class JSONRPCTransport: NSObject, JSONRPCTransporting {
    
    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
    var onMessage: ((String) -> ())?
    
    private let queue = OperationQueue()
    private var networkMonitor: NetworkMonitoring
    
    private let url: URL
    
    private lazy var socket: WebSocketSession = {
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: queue)
        let socket = WebSocketSession(session: urlSession)
        socket.onMessageReceived = { [weak self] in
            self?.onMessage?($0)
        }
        socket.onMessageError = { error in
            print(error)
        }
        return socket
    }()
    
    init(url: URL,
         networkMonitor: NetworkMonitoring = NetworkMonitor()) {
        self.url = url
        self.networkMonitor = networkMonitor
        super.init()
        socket.connect(on: url)
        setUpNetworkMonitoring()
    }

    func send(_ string: String, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            self.socket.send(string, completionHandler: completion)
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
    
    private func setUpNetworkMonitoring() {
        networkMonitor.onSatisfied = { [weak self] in
            self?.connect()
        }
        networkMonitor.onUnsatisfied = { [weak self] in
            self?.disconnect(closeCode: .goingAway)
        }
        networkMonitor.startMonitoring()
    }
}


extension JSONRPCTransport: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
        onConnect?()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
        onDisconnect?()
    }
}
//class Dispatcher {
//    func dispatch(_ string: String) {
//
//    }
//
//    private func dispatchAllFrames() {
//
//    }
//}
