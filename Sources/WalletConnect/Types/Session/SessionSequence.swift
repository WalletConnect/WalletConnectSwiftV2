import Foundation

struct SessionSequence: ExpirableSequence {
    
    let topic: String
    let relay: RelayProtocolOptions
    let selfParticipant: SessionType.Participant
    let expiryDate: Date
    private var sequenceState: Either<Pending, Settled>
}

extension SessionSequence {
    
    struct Pending: Codable {
        let status: SessionType.Pending.PendingStatus
        let proposal: SessionType.Proposal
    }
    
    struct Settled: Codable {
        let peer: SessionType.Participant
        let permissions: SessionType.Permissions
        let state: SessionType.State
    }
}
