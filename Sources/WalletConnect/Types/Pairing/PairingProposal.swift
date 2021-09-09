
import Foundation

extension PairingType {
    
    struct Proposal: Codable, SequenceProposal {
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

extension PairingType.Proposal {
    
    static func createFromURI(_ uri: PairingType.ParamsUri) -> PairingType.Proposal {
        PairingType.Proposal(
            topic: uri.topic,
            relay: uri.relay,
            proposer: PairingType.Proposer(
                publicKey: uri.publicKey,
                controller: uri.controller),
            signal: PairingType.Signal(params: PairingType.Signal.Params(uri: uri.raw)),
            permissions: PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [])),
            ttl: PairingType.defaultTTL
        )
    }
}
