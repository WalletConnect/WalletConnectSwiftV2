
import Foundation

struct SessionProposal: Codable, Equatable {
    let relays: [RelayProtocolOptions]
    let proposer: Participant
    let namespaces: Set<Namespace>
    
    func publicRepresentation() -> Session.Proposal {
        return Session.Proposal(id: proposer.publicKey, proposer: proposer.metadata, namespaces: namespaces, proposal: self)
    }
}
