import Foundation

enum WebSocketClientError: Error {
    case errorWithCode(URLSessionWebSocketTask.CloseCode)
}

struct WebSocketClientFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        return WCWebSocketClient(url: url, logger: ConsoleLogger(loggingLevel: .debug))
    }
}

final class WCWebSocketClient: NSObject, WebSocketConnecting {
    private var socket: URLSessionWebSocketTask? = nil
    private var url: URL
    private let logger: ConsoleLogging
    
    private var _request: URLRequest
    private var _isConnected = false
    
    private let lock = UnfairLock()
    
    init(url: URL, logger: ConsoleLogging) {
        self.url = url
        self.logger = logger
        self._request = URLRequest(url: url)
        super.init()
    }
    
    public func reconnect() {
        let configuration = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        let urlRequest = URLRequest(url: url)
        socket = urlSession.webSocketTask(with: urlRequest)
        
        isConnected = false
        connect()
    }
    
    // MARK: - WebSocketConnecting
    var isConnected: Bool {
        get { lock.withLock { _isConnected } }
        set { lock.withLock { _isConnected = newValue } }
    }
    
    var request: URLRequest {
        get { lock.withLock { _request } }
        set {
            lock.withLock {
                _request = newValue
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
    }
    
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?
    
    func connect() {
        lock.lock()
        defer {
            lock.unlock()
        }
        logger.debug("[WebSocketClient]: Connect called 🔗 \(url.host ?? "nil")")
        socket?.resume()
    }
    
    func disconnect() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        logger.debug("[WebSocketClient]: Disconnect called")
        socket?.cancel()
        isConnected = false
    }
    
    func write(string: String, completion: (() -> Void)?) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        let message = URLSessionWebSocketTask.Message.string(string)
        socket?.send(message) { _ in
            completion?()
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WCWebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        logger.debug("[WebSocketClient]: Connected")
        onConnect?()
        receiveMessage()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        if isConnected {
            isConnected = false
            logger.debug("[WebSocketClient]: Did close with code: \(closeCode)")
            onDisconnect?(WebSocketClientError.errorWithCode(closeCode))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        logger.debug("[WebSocketClient]: Did complete with error: \(error?.localizedDescription ?? "unknown")")
    }
    
    func receiveMessage() {
        socket?.receive { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .failure(let error):
                self.logger.debug("[WebSocketClient]: Error receiving: \(error)")
                let nsError = error as NSError
                if nsError.code == 57 && nsError.domain == "NSPOSIXErrorDomain" {
                    if self.isConnected {
                        self.isConnected = false
                        self.reconnect()
                    }
                }
                    
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
