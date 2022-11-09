import Foundation

public struct SessionProposal: Codable, Equatable {
    public let relays: [RelayProtocolOptions]
    public let proposer: Participant
    public let requiredNamespaces: [String: ProposalNamespace]

    func publicRepresentation() -> Session.Proposal {
        return Session.Proposal(id: proposer.publicKey, proposer: proposer.metadata, requiredNamespaces: requiredNamespaces, proposal: self)
    }
}
