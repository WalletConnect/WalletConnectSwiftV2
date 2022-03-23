
import Foundation

struct SessionState: Codable, Equatable {
    var accounts: [String]
}

struct SessionProposal: Codable, Equatable {
    struct ProposedBlockchain: Codable, Equatable {
        var chains: Set<String>
    }
    let relays: [RelayProtocolOptions]
    let proposer: Participant
    let permissions: SessionPermissions
    let blockchain: ProposedBlockchain
    
    func publicRepresentation() -> Session.Proposal {
        return Session.Proposal(proposer: proposer.metadata, permissions: Session.Permissions(permissions: permissions), blockchains: blockchain.chains, proposal: self)
    }
}
