import Foundation

final class WebSocketSession: NSObject {
    
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
    func webSocketTask(with url: URL) -> URLSessionWebSocketTaskProtocol
}

extension URLSession: URLSessionProtocol {
    func webSocketTask(with url: URL) -> URLSessionWebSocketTaskProtocol {
        webSocketTask(with: url) as URLSessionWebSocketTask
    }
}

protocol URLSessionWebSocketTaskProtocol {
    func resume()
    func cancel()
    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void)
    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void)
}

extension URLSessionWebSocketTask: URLSessionWebSocketTaskProtocol {}
