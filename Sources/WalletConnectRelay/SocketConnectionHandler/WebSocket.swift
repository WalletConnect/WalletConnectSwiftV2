import Foundation

public protocol WebSocketConnecting: AnyObject {
    var isConnected: Bool { get }
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: ((Error?) -> Void)? { get set }
    var onText: ((String) -> Void)? { get set }
    var request: URLRequest { get set }
    func connect()
    func disconnect()
    func write(string: String, completion: (() -> Void)?)
}

public protocol WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting
}

#if DEBUG
class WebSocketMock: WebSocketConnecting {
    var request: URLRequest = URLRequest(url: URL(string: "wss://relay.walletconnect.com")!)

    var onText: ((String) -> Void)?
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var sendCallCount: Int = 0
    var isConnected: Bool = false

    func connect() {
        isConnected = true
        onConnect?()
    }

    func disconnect() {
        isConnected = false
        onDisconnect?(nil)
    }

    func write(string: String, completion: (() -> Void)?) {
        sendCallCount+=1
    }
}
#endif

#if DEBUG
class WebSocketFactoryMock: WebSocketFactory {
    private let webSocket: WebSocketMock

    init(webSocket: WebSocketMock) {
        self.webSocket = webSocket
    }

    func create(with url: URL) -> WebSocketConnecting {
        return webSocket
    }
}
#endif
