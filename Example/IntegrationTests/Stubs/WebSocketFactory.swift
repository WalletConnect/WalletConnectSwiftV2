import Foundation
import Starscream
import WalletConnectRelay

extension WebSocket: WebSocketConnecting { }

public struct SocketFactory: WebSocketFactory {

    public init() { }

    public func create(with url: URL) -> WebSocketConnecting {
        return WebSocket(url: url)
    }
}
