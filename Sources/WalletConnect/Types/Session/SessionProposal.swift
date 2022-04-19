
import Foundation

struct SessionProposal: Codable, Equatable {
    let relays: [RelayProtocolOptions]
    let proposer: Participant
    let chains: Set<Blockchain>
    let methods: Set<String>
    let events: Set<String>
    
    func publicRepresentation() -> Session.Proposal {
        return Session.Proposal(proposer: proposer.metadata, methods: methods, events: events, chains: chains, proposal: self)
    }
}
