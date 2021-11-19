import Foundation

struct SessionSequence: ExpirableSequence {
    
    let topic: String
    let relay: RelayProtocolOptions
    let selfParticipant: SessionType.Participant
    let expiryDate: Date
    private var sequenceState: Either<Pending, Settled>
    
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
    
    var isController: Bool {
        guard let controller = settled?.permissions.controller else { return false }
        return selfParticipant.publicKey == controller.publicKey
    }
    
    var peerIsController: Bool {
        isSettled && settled?.peer.publicKey == settled?.permissions.controller?.publicKey
    }
    
    func hasPermission(forChain chainId: String) -> Bool {
        guard let settled = settled else { return false }
        return settled.permissions.blockchain.chains.contains(chainId)
    }
    
    func hasPermission(forMethod method: String) -> Bool {
        guard let settled = settled else { return false }
        return settled.permissions.jsonrpc.methods.contains(method)
    }
    
    mutating func upgrade(_ permissions: SessionPermissions) {
        settled?.permissions.upgrade(with: permissions)
    }
}

extension SessionSequence {
    
    init(topic: String, relay: RelayProtocolOptions, selfParticipant: SessionType.Participant, expiryDate: Date, pendingState: Pending) {
        self.init(topic: topic, relay: relay, selfParticipant: selfParticipant, expiryDate: expiryDate, sequenceState: .left(pendingState))
    }
    
    init(topic: String, relay: RelayProtocolOptions, selfParticipant: SessionType.Participant, expiryDate: Date, settledState: Settled) {
        self.init(topic: topic, relay: relay, selfParticipant: selfParticipant, expiryDate: expiryDate, sequenceState: .right(settledState))
    }
}

extension SessionSequence {
    
    struct Pending: Codable {
        let status: SessionType.Pending.PendingStatus
        let proposal: SessionType.Proposal
    }
    
    struct Settled: Codable {
        let peer: SessionType.Participant
        var permissions: SessionType.Permissions
        var state: SessionType.State
    }
}
