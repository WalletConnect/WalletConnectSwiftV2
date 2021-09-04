
import Foundation

extension PairingType {
    struct Proposal: Codable {
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
    }
    
    struct ProposedPermissions: Codable, Equatable {
        let jsonrpc: JSONRPC
    }
    
    struct Permissions: Codable, Equatable {
        let jsonrpc: JSONRPC
        let controller: Controller
    }
    
    struct JSONRPC: Codable, Equatable {
        let methods: [String]
    }
}
