
import Foundation

extension SessionType {
    public struct Proposal: Codable, Equatable {
        let topic: String
        let relay: RelayProtocolOptions
        let proposer: Proposer
        let signal: Signal
        let permissions: ProposedPermissions
        let ttl: Int
    }
    
    struct Proposer: Codable, Equatable {
        let publicKey: String
        let controller: Bool
        let metadata: AppMetadata
    }
    
    public struct ProposedPermissions: Codable, Equatable {
        let blockchain: Blockchain
        let jsonrpc: JSONRPC
        let notifications: Notifications?
    }
    
    struct Permissions: Codable, Equatable {
        let blockchain: Blockchain
        let jsonrpc: JSONRPC
        let notifications: Notifications?
        let controller: Controller
    }
    
    struct Blockchain: Codable, Equatable {
        let chains: [String]
    }
    
    struct JSONRPC: Codable, Equatable {
        let methods: [String]
    }
    
    struct Notifications: Codable, Equatable {
        let types: [String]
    }
}
