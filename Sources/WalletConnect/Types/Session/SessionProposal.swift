
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
    
    struct Signal: Codable, Equatable {
        struct Params: Codable, Equatable {
            let topic: String
        }
        let method: String
        let params: Params
    }
    
    public struct Permissions: Codable, Equatable {
        public private(set) var blockchain: Blockchain
        public private(set) var jsonrpc: JSONRPC
        let notifications: Notifications?
        var controller: Controller?
        
        internal init(blockchain: SessionType.Blockchain, jsonrpc: SessionType.JSONRPC, notifications: SessionType.Notifications? = nil, controller: Controller? = nil) {
            self.blockchain = blockchain
            self.jsonrpc = jsonrpc
            self.notifications = notifications
            self.controller = controller
        }
        
        public init(blockchain: SessionType.Blockchain, jsonrpc: SessionType.JSONRPC, notifications: SessionType.Notifications) {
            self.blockchain = blockchain
            self.jsonrpc = jsonrpc
            self.notifications = notifications
            self.controller = nil
        }
        
        mutating func upgrade(with sessionPermissions: SessionPermissions) {
            blockchain.chains.formUnion(sessionPermissions.blockchains)
            jsonrpc.methods.formUnion(sessionPermissions.methods)
        }
    }
    
    public struct Blockchain: Codable, Equatable {
        fileprivate(set) var chains: Set<String>
        
        public init(chains: Set<String>) {
            self.chains = chains
        }
    }
    
    public struct JSONRPC: Codable, Equatable {
        fileprivate(set) var methods: Set<String>
        
        public init(methods: Set<String>) {
            self.methods = methods
        }
    }
    
    public struct Notifications: Codable, Equatable {
        let types: [String]
        public init(types: [String]) {
            self.types = types
        }
    }
}
