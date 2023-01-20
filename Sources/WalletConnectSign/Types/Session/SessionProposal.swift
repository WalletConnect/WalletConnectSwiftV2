import Foundation

struct SessionProposal: Codable, Equatable {
    let relays: [RelayProtocolOptions]
    let proposer: Participant
    let requiredNamespaces: [String: ProposalNamespace]

    func publicRepresentation(pairingTopic: String) -> Session.Proposal {
        return Session.Proposal(
            id: proposer.publicKey,
            pairingTopic: pairingTopic,
            proposer: proposer.metadata,
            requiredNamespaces: requiredNamespaces,
            proposal: self
        )
    }
}
