import Foundation

extension Relay {
    struct Config {
        internal init(relayHost: String, projectId: String, socketFactory: WebSocketFactory, socketConnectionType: SocketConnectionType) {
            self.relayHost = relayHost
            self.projectId = projectId
            self.socketFactory = socketFactory
            self.socketConnectionType = socketConnectionType
        }
        
        let relayHost: String
        let projectId: String
        let socketFactory: WebSocketFactory
        let socketConnectionType: SocketConnectionType
    }
}
