import Foundation
import Starscream
import WalletConnectRelay

extension WebSocket: WebSocketConnecting {
    public func reconnect() {
        self.connect()
    }
}

struct DefaultSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        let socket = WebSocket(url: url)
        let queue = DispatchQueue(label: "com.walletconnect.sdk.sockets", attributes: .concurrent)
        socket.callbackQueue = queue
        return socket
    }
}
