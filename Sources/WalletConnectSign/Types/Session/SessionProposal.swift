import Foundation

struct SessionProposal: Codable, Equatable {
    let relays: [RelayProtocolOptions]
    let proposer: Participant
    let requiredNamespaces: [String: ProposalNamespace]

    func publicRepresentation() -> Session.Proposal {
        return Session.Proposal(id: proposer.publicKey, proposer: proposer.metadata, requiredNamespaces: requiredNamespaces, proposal: self)
    }
}
