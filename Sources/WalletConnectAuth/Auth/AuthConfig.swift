import WalletConnectRelay
import Foundation

public extension Auth {
    struct Config {
        let metadata: AppMetadata
        let projectId: String
        let socketConnectionType: SocketConnectionType
        
        public init(metadata: AppMetadata, projectId: String, socketConnectionType: SocketConnectionType = .automatic) {
            self.metadata = metadata
            self.projectId = projectId
            self.socketConnectionType = socketConnectionType
        }
    }
}
