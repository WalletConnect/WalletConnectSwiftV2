import Foundation

enum WebSocketClientError: Error {
    case errorWithCode(URLSessionWebSocketTask.CloseCode)
}

struct WebSocketClientFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        return WebSocketClient(withURL: url, logger: ConsoleLogger(loggingLevel: .debug))
    }
}

final class WebSocketClient: NSObject, WebSocketConnecting {
    private var socket: URLSessionWebSocketTask? = nil
    private var url: URL
    private let logger: ConsoleLogging
    
    init(withURL url: URL, logger: ConsoleLogging) {
        self.url = url
        self.logger = logger
        self.isConnected = false
        self.request = URLRequest(url: url)
        super.init()
    }
    
    func reconnect() {
        let configuration = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        let urlRequest = URLRequest(url: url)
        socket = urlSession.webSocketTask(with: urlRequest)

        isConnected = false
        connect()
    }
    
    // MARK: - WebSocketConnecting
    var isConnected: Bool
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?
    var request: URLRequest {
        didSet {
            if let url = request.url {
                let configuration = URLSessionConfiguration.default
                let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
                let urlRequest = URLRequest(url: url)
                socket = urlSession.webSocketTask(with: urlRequest)

                isConnected = false
                self.url = url
            }
        }
    }
    
    func connect() {
        logger.debug("[WebSocketClient]: Connect called")
        socket?.resume()
    }
    
    func disconnect() {
        logger.debug("[WebSocketClient]: Disconnect called")
        socket?.cancel()
    }
    
    func write(string: String, completion: (() -> Void)?) {
        let message = URLSessionWebSocketTask.Message.string(string)
        socket?.send(message) { _ in
            completion?()
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        logger.debug("[WebSocketClient]: Connected")
        onConnect?()
        receiveMessage()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        logger.debug("[WebSocketClient]: Did close with code: \(closeCode)")
        onDisconnect?(WebSocketClientError.errorWithCode(closeCode))
    }
    
    func receiveMessage() {
        socket?.receive { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .failure(let error):
                self.logger.debug("[WebSocketClient]: Error receiving: \(error)")
                self.isConnected = false
                    
            case .success(let message):
                switch message {
                case .string(let messageString):
                    self.logger.debug("[WebSocketClient]: Received message:  \(messageString)")
                    self.onText?(messageString)
                            
                case .data(let data):
                    self.logger.debug("[WebSocketClient]: Received data: \(data.description)")
                    self.onText?(data.description)
                            
                default:
                    self.logger.debug("[WebSocketClient]: Received unknown data")
                }
            }
            
            if self.isConnected == true {
                self.receiveMessage()
            }
        }
    }
}
