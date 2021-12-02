import Foundation

struct PairingSequence: ExpirableSequence {
    let topic: String
    let relay: RelayProtocolOptions
    let selfParticipant: PairingType.Participant
    let expiryDate: Date
    private var sequenceState: Either<Pending, Settled>
    
    var publicKey: String {
        selfParticipant.publicKey
    }

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
    
    var isSettled: Bool {
        settled != nil
    }
    
    var peerIsController: Bool {
        isSettled && settled?.peer.publicKey == settled?.permissions.controller.publicKey
    }
    
    static var timeToLivePending: Int {
        Time.day
    }
    
    static var timeToLiveSettled: Int {
        Time.day * 30
    }
}

extension PairingSequence {
    
    init(topic: String, relay: RelayProtocolOptions, selfParticipant: PairingType.Participant, expiryDate: Date, pendingState: Pending) {
        self.init(topic: topic, relay: relay, selfParticipant: selfParticipant, expiryDate: expiryDate, sequenceState: .left(pendingState))
    }
    
    init(topic: String, relay: RelayProtocolOptions, selfParticipant: PairingType.Participant, expiryDate: Date, settledState: Settled) {
        self.init(topic: topic, relay: relay, selfParticipant: selfParticipant, expiryDate: expiryDate, sequenceState: .right(settledState))
    }
}
    
extension PairingSequence {    
    struct Pending: Codable {
        let proposal: PairingType.Proposal
        let status: PairingType.Pending.PendingStatus
    }

    struct Settled: Codable {
        let peer: PairingType.Participant
        let permissions: PairingType.Permissions
        var state: PairingType.State?
        var status: PairingType.Settled.SettledStatus
    }
}
