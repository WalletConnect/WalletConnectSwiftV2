import Foundation
import WalletConnectRelay

public extension Sign {
    struct Config {
        let metadata: AppMetadata
        let relayHost: String
        let projectId: String
        let socketFactory: WebSocketFactory
        let socketConnectionType: SocketConnectionType

        public init(
            metadata: AppMetadata,
            relayHost: String,
            projectId: String,
            socketFactory: WebSocketFactory,
            socketConnectionType: SocketConnectionType = .automatic
        ) {
            self.metadata = metadata
            self.relayHost = relayHost
            self.projectId = projectId
            self.socketFactory = socketFactory
            self.socketConnectionType = socketConnectionType
        }
    }
}
