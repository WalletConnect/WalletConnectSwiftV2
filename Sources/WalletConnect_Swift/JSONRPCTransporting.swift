// 

import Foundation

protocol JSONRPCTransporting {
    var onMessage: ((String)->())? {get set}
    func send(_ string: String, completion: @escaping (Error?)->())
    func disconnect()
}

class JSONRPCTransport: NSObject, JSONRPCTransporting, URLSessionWebSocketDelegate {
    var onMessage: ((String) -> ())?
    var session: URLSession!
    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
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
        session.webSocketTask(with: url)
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
          case .data(let data):
            print("Data received \(data)")
          case .string(let text):
            print("Text received \(text)")
          }
        case .failure(let error):
          print("Error when receiving \(error)")
        }
        self.listen()
      }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
    }
}
