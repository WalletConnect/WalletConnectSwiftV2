
import Foundation

struct SessionState: Codable, Equatable {
    var accounts: [String]
}

struct SessionProposal: Codable, Equatable {
    let relays: [RelayProtocolOptions]
    let proposer: Participant
    let permissions: SessionPermissions
    let blockchain: Blockchain
    
    func publicRepresentation() -> Session.Proposal {
        return Session.Proposal(proposer: proposer.metadata, permissions: Session.Permissions(permissions: permissions), blockchains: blockchain.chains, proposal: self)
    }
}


struct Blockchain: Codable, Equatable {
    var chains: Set<String>
    var accounts: Set<Account>
}
