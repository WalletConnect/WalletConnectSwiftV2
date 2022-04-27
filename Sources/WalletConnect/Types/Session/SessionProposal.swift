
import Foundation

struct SessionProposal: Codable, Equatable {
    let relays: [RelayProtocolOptions]
    let proposer: Participant
    let chains: Set<Blockchain>
    let namespaces: Set<Namespace>
    
    func publicRepresentation() -> Session.Proposal {
        return Session.Proposal(proposer: proposer.metadata, namespaces: namespaces, chains: chains, proposal: self)
    }
}
