import Foundation

struct PairingSequence: ExpirableSequence {
    let topic: String
    let relay: RelayProtocolOptions
    let `self`: PairingType.Participant
    let expiryDate: Date
    let sequenceState: Either<Pending, Settled>

    struct Pending: Codable {
        let proposal: PairingType.Proposal
        let status: PairingType.Pending.PendingStatus
    }

    struct Settled: Codable {
        let peer: PairingType.Participant
        let permissions: PairingType.Permissions
        let state: PairingType.State?
    }
}

public struct Pairing {
    public let topic: String
    public let peer: AppMetadata? // TODO: Remove optional, there's always a peer
}
