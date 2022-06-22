import WalletConnectRelay
import Foundation

public extension Sign {
    struct Config {
        let metadata: AppMetadata
        let projectId: String
        let socketImplementation: WebSocketConnecting.Type
        let socketConnectionType: SocketConnectionType

        public init(
            metadata: AppMetadata,
            projectId: String,
            socketImplementation: WebSocketConnecting.Type,
            socketConnectionType: SocketConnectionType = .automatic
        ) {
            self.metadata = metadata
            self.projectId = projectId
            self.socketImplementation = socketImplementation
            self.socketConnectionType = socketConnectionType
        }
    }
}
