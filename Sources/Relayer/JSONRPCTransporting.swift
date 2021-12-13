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
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.walletconnect.sdk.network.monitor")
    
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
    
    init(url: URL) {
        self.url = url
        super.init()
        socket.connect(on: url)
        startNetworkMonitoring()
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
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.connect()
            } else {
                self?.disconnect(closeCode: .goingAway)
            }
        }
        monitor.start(queue: monitorQueue)
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
