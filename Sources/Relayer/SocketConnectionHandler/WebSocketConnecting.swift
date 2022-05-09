import Starscream
import Foundation

extension WebSocket: WebSocketConnecting{}

protocol WebSocketConnecting {
    var isConnected: Bool {get}
    func connect()
    func disconnect()
}
