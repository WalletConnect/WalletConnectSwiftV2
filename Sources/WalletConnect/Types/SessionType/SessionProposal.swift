
import Foundation

extension SessionType {
    struct Proposal: Codable {
        let topic: String
        let relay: RelayProtocolOptions
        let proposer: Proposer
        let signal: Signal
        let permissions: ProposedPermissions
        let ttl: Int
    }
    
    struct Proposer: Codable {
        let publicKey: String
        let controller: Bool
        let metadata: AppMetadata
    }
    
    struct ProposedPermissions: Codable {
        let blockchain: Blockchain
        let jsonrpc: JSONRPC
        let notifications: Notifications
    }
    
    struct Permissions: Codable {
        let blockchain: Blockchain
        let jsonrpc: JSONRPC
        let notifications: Notifications
        let controller: Controller
    }
    
    struct Blockchain: Codable {
        let chains: [String]
    }
    
    struct JSONRPC: Codable {
        let methods: [String]
    }
    
    struct Notifications: Codable {
        let types: [String]
    }
}
