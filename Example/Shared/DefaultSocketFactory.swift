import Foundation

import Starscream
import WalletConnectRelay

extension WebSocket: WebSocketConnecting {
    public func reconnect() {
        
    }
}

struct DefaultSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        return WebSocket(url: url)
    }
}
