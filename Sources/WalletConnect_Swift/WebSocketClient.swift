import Foundation

final class WebSocketClient: NSObject {
    
    private let session: URLSession
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    init(session: URLSession) {
        self.session = session
        super.init()
    }
    
    func connect(on url: URL) {
        webSocketTask = session.webSocketTask(with: url)
        listen()
        webSocketTask?.resume()
    }
    
    func disconnect() {
        webSocketTask?.cancel() // TODO: specify a reason
        webSocketTask = nil
    }
    
    func send(_ message: String) {
        webSocketTask?.send(.string(message)) { error in
            // TODO: Handle error
        }
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                break // TODO: Handle message event
            case .failure(let error):
                break // TODO: Handle error
            }
            self?.listen()
        }
    }
}

protocol URLSessionProtocol {
}
