
import Foundation

struct SessionProposal: Codable, Equatable {
    let relays: [RelayProtocolOptions]
    let proposer: Participant
    let methods: Set<String>
    let events: Set<String>
    let chains: Set<Blockchain>
    
    func publicRepresentation() -> Session.Proposal {
        return Session.Proposal(proposer: proposer.metadata, methods: methods, events: events, blockchains: chains, proposal: self)
    }
}
