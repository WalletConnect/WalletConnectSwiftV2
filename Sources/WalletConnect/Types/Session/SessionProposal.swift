
import Foundation

struct SessionState: Codable, Equatable {
    var accounts: [String]
}

struct SessionProposal: Codable, Equatable {
    let relay: RelayProtocolOptions
    let proposer: Participant
    let permissions: SessionPermissions
    let blockchainProposed: Blockchain
    
    func publicRepresentation() -> Session.Proposal {
        return Session.Proposal(proposer: proposer.metadata, permissions: Session.Permissions(permissions: permissions), blockchains: blockchainProposed.chains, proposal: self)
    }
}


struct Blockchain: Codable, Equatable {
    var chains: Set<String>
    var accounts: Set<Account>
}
