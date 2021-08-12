// 

import Foundation

public protocol JSONRPCTransporting {
    func listen(on url: URL)
    func send(_ string: String)
    func disconnect()
    func ping()
}

public class JSONRPCTransport: NSObject, JSONRPCTransporting, URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
    }
    public override init() {
        super.init()
    }
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
    }
    var session: URLSession!

    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
    var onReceiveMessage: (() -> ())?
    var webSocketTask: URLSessionWebSocketTask!
    
    public func listen(on url: URL) {
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        session.webSocketTask(with: url)
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask.resume()
        listen()
    }
    
    public func send(_ string: String)  {
        DispatchQueue.global().async {
            self.webSocketTask.send(.string(string)) { error in
              if let error = error {
                print("Error when sending a message \(error)")
              }
            }
        }
    }
    
    func listen() {
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

    public func ping() {
      webSocketTask.sendPing { error in
        if let error = error {
          print("Error when sending PING \(error)")
        } else {
            print("Web Socket connection is alive")
        }
      }
    }
    
    public func disconnect() {
        let reason = "Closing connection".data(using: .utf8)
        webSocketTask.cancel(with: .goingAway, reason: reason)
    }
}
