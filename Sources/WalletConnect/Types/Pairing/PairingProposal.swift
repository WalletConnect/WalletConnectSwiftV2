
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
    
    struct Proposer: Codable {
        let publicKey: String
        let controller: Bool
    }
    
    struct ProposedPermissions: Codable {
        let jsonrpc: JSONRPC
    }
    
    struct Permissions: Codable {
        let jsonrpc: JSONRPC
        let controller: Controller
    }
    
    struct JSONRPC: Codable {
        let methods: [String]
    }
}
