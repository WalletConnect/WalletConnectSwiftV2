import Foundation

struct PairingSequence: ExpirableSequence {
    let topic: String
    let relay: RelayProtocolOptions
    let selfParticipant: PairingType.Participant
    let expiryDate: Date
    var sequenceState: Either<Pending, Settled>

    var pending: Pending? {
        get {
            sequenceState.left
        }
        set {
            if let pending = newValue {
                sequenceState = .left(pending)
            }
        }
    }
    
    var settled: Settled? {
        get {
            sequenceState.right
        }
        set {
            if let settled = newValue {
                sequenceState = .right(settled)
            }
        }
    }
    
    
    struct Pending: Codable {
        let proposal: PairingType.Proposal
        let status: PairingType.Pending.PendingStatus
    }

    struct Settled: Codable {
        let peer: PairingType.Participant
        let permissions: PairingType.Permissions
        var state: PairingType.State?
        
        var peerIsController: Bool {
            peer.publicKey == permissions.controller.publicKey
        }
    }
    
    init(topic: String, relay: RelayProtocolOptions, selfParticipant: PairingType.Participant, expiryDate: Date, pendingState: Pending) {
        self.init(topic: topic, relay: relay, selfParticipant: selfParticipant, expiryDate: expiryDate, sequenceState: .left(pendingState))
    }
    
    init(topic: String, relay: RelayProtocolOptions, selfParticipant: PairingType.Participant, expiryDate: Date, settledState: Settled) {
        self.init(topic: topic, relay: relay, selfParticipant: selfParticipant, expiryDate: expiryDate, sequenceState: .right(settledState))
    }
    
    private init(topic: String, relay: RelayProtocolOptions, selfParticipant: PairingType.Participant, expiryDate: Date, sequenceState: Either<PairingSequence.Pending, PairingSequence.Settled>) {
        self.topic = topic
        self.relay = relay
        self.selfParticipant = selfParticipant
        self.expiryDate = expiryDate
        self.sequenceState = sequenceState
    }
}

public struct Pairing {
    public let topic: String
    public let peer: AppMetadata? // TODO: Remove optional, there's always a peer
}
