import Foundation

struct SessionProposal: Codable, Equatable {
    
    let relays: [RelayProtocolOptions]
    let proposer: Participant
    let requiredNamespaces: [String: ProposalNamespace]
    let optionalNamespaces: [String: ProposalNamespace]?
    let sessionProperties: [String: String]?
    let expiry: UInt64?

    static let proposalExpiry: TimeInterval = 300 // 5 minutes

    internal init(relays: [RelayProtocolOptions],
                  proposer: Participant,
                  requiredNamespaces: [String : ProposalNamespace],
                  optionalNamespaces: [String : ProposalNamespace]? = nil,
                  sessionProperties: [String : String]? = nil) {
        self.relays = relays
        self.proposer = proposer
        self.requiredNamespaces = requiredNamespaces
        self.optionalNamespaces = optionalNamespaces
        self.sessionProperties = sessionProperties
        self.expiry = UInt64(Date().timeIntervalSince1970 + Self.proposalExpiry)
    }

    func publicRepresentation(pairingTopic: String) -> Session.Proposal {
        return Session.Proposal(
            id: proposer.publicKey,
            pairingTopic: pairingTopic,
            proposer: proposer.metadata,
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces ?? [:],
            sessionProperties: sessionProperties,
            proposal: self
        )
    }

    func isExpired(currentDate: Date = Date()) -> Bool {
        guard let expiry = expiry else { return false }

        let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiry))

        return expiryDate < currentDate
    }
}
