import Foundation

extension Networking {
    struct Config {
        let relayHost: String
        let groupIdentifier: String
        let projectId: String
        let socketFactory: WebSocketFactory
        let socketConnectionType: SocketConnectionType
    }
}
