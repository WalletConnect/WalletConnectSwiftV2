import Foundation
import WalletConnectRelay

extension Networking {
    struct Config {
        let relayHost: String
        let projectId: String
        let socketFactory: WebSocketFactory
        let socketConnectionType: SocketConnectionType
    }
}
