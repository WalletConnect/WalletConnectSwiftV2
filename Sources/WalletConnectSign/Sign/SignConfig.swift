import Foundation
import WalletConnectRelay
import WalletConnectUtils

public extension Sign {
    struct Config {
        let metadata: AppMetadata
        let projectId: String
        let socketFactory: WebSocketFactory
        let socketConnectionType: SocketConnectionType

        public init(
            metadata: AppMetadata,
            projectId: String,
            socketFactory: WebSocketFactory,
            socketConnectionType: SocketConnectionType = .automatic
        ) {
            self.metadata = metadata
            self.projectId = projectId
            self.socketFactory = socketFactory
            self.socketConnectionType = socketConnectionType
        }
    }
}
