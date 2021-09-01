// 

import Foundation

protocol JSONRPCTransporting {
    var onPayload: ((String)->())? {get set}
    var onConnected: (()->())? {get set}
    var onDisconnected: (()->())? {get set}
    func send(_ string: String, completion: @escaping (Error?)->())
    func disconnect()
}

class JSONRPCTransport: NSObject, JSONRPCTransporting, URLSessionWebSocketDelegate {
    var onConnected: (() -> ())?
    var onDisconnected: (() -> ())?
    var onPayload: ((String) -> ())?
    var session: URLSession!
    var onReceiveMessage: (() -> ())?
    var webSocketTask: URLSessionWebSocketTask!
    
    init(url: URL) {
        super.init()
        listen(on: url)
    }

    func send(_ string: String, completion: @escaping (Error?)->())  {
        DispatchQueue.global().async {
            self.webSocketTask.send(.string(string)) { error in
            completion(error)
              if let error = error {
                print("Error when sending a message \(error)")
              }
            }
        }
    }
    
    public func disconnect() {
        let reason = "Closing connection".data(using: .utf8)
        webSocketTask.cancel(with: .goingAway, reason: reason)
    }
    
    private func listen(on url: URL) {
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask.resume()
        listen()
    }
    
    private func listen() {
      webSocketTask.receive { [unowned self] result in
        switch result {
        case .success(let message):
          switch message {
          case .string(let text):
            Logger.debug("Transport: Text received \(text)")
            onPayload?(text)
          default:
            Logger.debug("Transport: Unexpected type of message received")
          }
        case .failure(let error):
            Logger.debug("Error when receiving \(error)")
        }
        self.listen()
      }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
        onDisconnected?()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
        onConnected?()
    }
}
