import Foundation

final class WebSocketSession: NSObject {
    
    var onMessageReceived: ((String) -> ())?
    var onError: ((Error) -> ())?
    
    private let session: URLSessionProtocol
    
    private var webSocketTask: URLSessionWebSocketTaskProtocol?
    
    var isConnected: Bool {
        webSocketTask != nil
    }
    
    init(session: URLSessionProtocol) {
        self.session = session
        super.init()
    }
    
    func connect(on url: URL) {
        webSocketTask = session.webSocketTask(with: url)
        listen()
        webSocketTask?.resume()
    }
    
    func disconnect() {
        webSocketTask?.cancel() // TODO: specify a reason?
        webSocketTask = nil
    }
    
    func send(_ message: String) {
        webSocketTask?.send(.string(message)) { [weak self] error in
            if let error = error {
                self?.onError?(error) // TODO: Handle different error types
            }
        }
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
            case .failure(let error):
                self?.onError?(error) // TODO: Handle different error types
            }
            self?.listen()
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            onMessageReceived?(text)
        default:
            Logger.debug("Transport: Unexpected type of message received")
        }
    }
}
