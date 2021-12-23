import Foundation
import CryptoKit

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
    
    static var timeToLiveProposed: Int {
        Time.hour
    }
    
    static var timeToLivePending: Int {
        Time.day
    }
    
    static var timeToLiveSettled: Int {
        Time.day * 30
    }
}

// MARK: - Initialization

extension PairingSequence {
    
    init(topic: String, relay: RelayProtocolOptions, selfParticipant: PairingType.Participant, expiryDate: Date, pendingState: Pending) {
        self.init(topic: topic, relay: relay, selfParticipant: selfParticipant, expiryDate: expiryDate, sequenceState: .left(pendingState))
    }
    
    init(topic: String, relay: RelayProtocolOptions, selfParticipant: PairingType.Participant, expiryDate: Date, settledState: Settled) {
        self.init(topic: topic, relay: relay, selfParticipant: selfParticipant, expiryDate: expiryDate, sequenceState: .right(settledState))
    }
    
    static func buildProposedFromURI(_ uri: WalletConnectURI) -> PairingSequence {
        let proposal = PairingProposal.createFromURI(uri)
        return PairingSequence(
            topic: proposal.topic,
            relay: proposal.relay,
            selfParticipant: PairingType.Participant(publicKey: proposal.proposer.publicKey),
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(timeToLiveProposed)),
            pendingState: Pending(proposal: proposal, status: .proposed)
        )
    }
    
    static func buildRespondedFromProposal(_ proposal: PairingProposal, agreementKeys: AgreementKeys) -> PairingSequence {
        PairingSequence(
            topic: proposal.topic,
            relay: proposal.relay,
            selfParticipant: PairingType.Participant(publicKey: agreementKeys.publicKey.hexRepresentation),
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(Time.day)),
            pendingState: Pending(
                proposal: proposal,
                status: .responded(agreementKeys.derivedTopic())
            )
        )
    }
    
    static func buildPreSettledFromProposal(_ proposal: PairingProposal, agreementKeys: AgreementKeys) -> PairingSequence {
        let controllerKey = proposal.proposer.controller ? proposal.proposer.publicKey : agreementKeys.publicKey.hexRepresentation
        return PairingSequence(
            topic: agreementKeys.derivedTopic(),
            relay: proposal.relay,
            selfParticipant: PairingType.Participant(publicKey: agreementKeys.publicKey.hexRepresentation),
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(proposal.ttl)),
            settledState: Settled(
                peer: PairingType.Participant(publicKey: proposal.proposer.publicKey),
                permissions: PairingType.Permissions(
                    jsonrpc: proposal.permissions.jsonrpc,
                    controller: Controller(publicKey: controllerKey)),
                state: nil,
                status: .preSettled
            )
        )
    }
    
    static func buildAcknowledgedFromApproval(_ approveParams: PairingType.ApproveParams, proposal: PairingProposal, agreementKeys: AgreementKeys) -> PairingSequence {
        let controllerKey = proposal.proposer.controller ? proposal.proposer.publicKey : approveParams.responder.publicKey
        return PairingSequence(
            topic: agreementKeys.derivedTopic(),
            relay: approveParams.relay , // Is it safe to just accept the approval params blindly?
            selfParticipant: PairingType.Participant(publicKey: agreementKeys.publicKey.hexRepresentation),
            expiryDate: Date(timeIntervalSince1970: TimeInterval(approveParams.expiry)),
            settledState: Settled(
                peer: PairingType.Participant(publicKey: approveParams.responder.publicKey),
                permissions: PairingType.Permissions(
                    jsonrpc: proposal.permissions.jsonrpc,
                    controller: Controller(publicKey: controllerKey)),
                state: approveParams.state,
                status: .acknowledged
            )
        )
    }
}
    
extension PairingSequence {
    
    struct Pending: Codable {
        let proposal: PairingProposal
        let status: Status
        
        var isResponded: Bool {
            guard case .responded = status else { return false }
            return true
        }
        
        enum Status: Codable {
            case proposed
            case responded(String)
        }
    }

    struct Settled: Codable {
        let peer: PairingType.Participant
        let permissions: PairingType.Permissions
        var state: PairingType.State?
        var status: PairingType.Settled.SettledStatus
    }
}
