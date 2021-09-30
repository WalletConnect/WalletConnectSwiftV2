
import Foundation

extension SessionType {
    public struct Proposal: Codable, Equatable {
        let topic: String
        let relay: RelayProtocolOptions
        let proposer: Proposer
        let signal: Signal
        let permissions: Permissions
        let ttl: Int
    }
    
    struct Proposer: Codable, Equatable {
        let publicKey: String
        let controller: Bool
        let metadata: AppMetadata
    }
    
    public struct Permissions: Codable, Equatable {
        let blockchain: Blockchain
        let jsonrpc: JSONRPC
        let notifications: Notifications?
        let controller: Controller?
        
        internal init(blockchain: SessionType.Blockchain, jsonrpc: SessionType.JSONRPC, notifications: SessionType.Notifications? = nil, controller: Controller? = nil) {
            self.blockchain = blockchain
            self.jsonrpc = jsonrpc
            self.notifications = notifications
            self.controller = controller
        }
        
        public init(blockchain: SessionType.Blockchain, jsonrpc: SessionType.JSONRPC) {
            self.blockchain = blockchain
            self.jsonrpc = jsonrpc
            self.notifications = nil
            self.controller = nil
        }
    }
    
    public struct Blockchain: Codable, Equatable {
        let chains: [String]
    }
    
    public struct JSONRPC: Codable, Equatable {
        let methods: [String]
    }
    
    struct Notifications: Codable, Equatable {
        let types: [String]
    }
}
