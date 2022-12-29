import Foundation
import Starscream
import WalletConnectRelay

struct SocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        return WebSocket(url: url)
    }
}
