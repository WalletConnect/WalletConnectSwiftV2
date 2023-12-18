import Foundation

extension Relay {
    struct Config {
        let relayHost: String
        let projectId: String
        let groupIdentifier: String
        let socketFactory: WebSocketFactory
        let socketConnectionType: SocketConnectionType
    }
}
