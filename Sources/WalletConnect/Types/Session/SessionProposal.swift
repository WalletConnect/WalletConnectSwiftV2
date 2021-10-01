
import Foundation

extension SessionType {
    public struct Proposal: Codable, Equatable {
        public let topic: String
        let relay: RelayProtocolOptions
        public let proposer: Proposer
        let signal: Signal
        public let permissions: Permissions
        public let ttl: Int
    }
    
    public struct Proposer: Codable, Equatable {
        let publicKey: String
        let controller: Bool
        public let metadata: AppMetadata
    }
    
    public struct Permissions: Codable, Equatable {
        public let blockchain: Blockchain
        public let jsonrpc: JSONRPC
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
        public let chains: [String]
        
        public init(chains: [String]) {
            self.chains = chains
        }
    }
    
    public struct JSONRPC: Codable, Equatable {
        public let methods: [String]
        
        public init(methods: [String]) {
            self.methods = methods
        }
    }
    
    struct Notifications: Codable, Equatable {
        let types: [String]
    }
}
