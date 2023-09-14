import Foundation

enum WalletConnectSocketClientError: Error {
    case errorWithCode(URLSessionWebSocketTask.CloseCode)
}

public struct WalletConnectSocketClientFactory: WebSocketFactory {
    public init() { }
    
    public func create(with url: URL) -> WebSocketConnecting {
        return WalletConnectSocketClient(url: url, logger: ConsoleLogger(loggingLevel: .debug))
    }
}

public final class WalletConnectSocketClient: NSObject, WebSocketConnecting {
    private var socket: URLSessionWebSocketTask? = nil
    private var url: URL
    private let logger: ConsoleLogging
    
    private var _request: URLRequest
    private var _isConnected = false
    
    // MARK: - WebSocketConnecting
    public var isConnected: Bool {
        get {
            lock.locked {
                _isConnected
            }
        }
        
        set {
            lock.locked {
                _isConnected = newValue
            }
        }
    }
    
    public var request: URLRequest {
        get {
            lock.locked {
                _request
            }
        }
        
        set {
            lock.locked {
                _request = newValue
                if let url = _request.url {
                    self.url = url
                    createSocketConnection()
                    _isConnected = false
                }
            }
        }
    }
    
    public var onConnect: (() -> Void)?
    public var onDisconnect: ((Error?) -> Void)?
    public var onText: ((String) -> Void)?
    
    private let lock = UnfairLock()
    
    init(url: URL, logger: ConsoleLogging) {
        self.url = url
        self.logger = logger
        self._request = URLRequest(url: url)
        super.init()
    }
    
    // MARK: - WebSocketConnecting
    public func connect() {
        lock.locked {
            logger.debug("[WebSocketClient]: Connect called 🔗 \(url.host ?? "nil")")
            socket?.resume()
        }
    }
    
    public func disconnect() {
        lock.locked {
            logger.debug("[WebSocketClient]: Disconnect called")
            socket?.cancel()
            _isConnected = false
        }
    }
    
    public func write(string: String, completion: (() -> Void)?) {
        lock.locked {
            let message = URLSessionWebSocketTask.Message.string(string)
            socket?.send(message) { _ in
                completion?()
            }
        }
    }
    
    public func reconnect() {
        createSocketConnection()
        
        isConnected = false
        connect()
    }
    
    private func createSocketConnection() {
        let configuration = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        let urlRequest = URLRequest(url: url)
        socket = urlSession.webSocketTask(with: urlRequest)
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WalletConnectSocketClient: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        logger.debug("[WebSocketClient]: Connected")
        onConnect?()
        receiveMessage()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        if isConnected {
            isConnected = false
            logger.debug("[WebSocketClient]: Did close with code: \(closeCode)")
            onDisconnect?(WalletConnectSocketClientError.errorWithCode(closeCode))
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
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
