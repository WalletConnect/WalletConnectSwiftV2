import Foundation
import WalletConnectKMS

struct SessionSequence: ExpirableSequence {
    let topic: String
    let relay: RelayProtocolOptions
    let selfParticipant: Participant
    private (set) var expiryDate: Date
    private var sequenceState: Either<Pending, Settled>

    var publicKey: String? {
        selfParticipant.publicKey
    }
    
    func getPublicKey() throws -> AgreementPublicKey {
        try AgreementPublicKey(rawRepresentation: Data(hex: selfParticipant.publicKey))
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
        settled?.status == .acknowledged
    }
    
    var selfIsController: Bool {
        guard let controller = settled?.permissions.controller else { return false }
        return selfParticipant.publicKey == controller.publicKey
    }
    
    var peerIsController: Bool {
        isSettled && settled?.peer.publicKey == settled?.permissions.controller?.publicKey
    }
    
    static var timeToLiveProposed: Int {
        Time.hour
    }
    
    static var timeToLivePending: Int {
        Time.day
    }
    
    static var timeToLiveSettled: Int {
        Time.day * 7
    }
    
    func hasPermission(forChain chainId: String) -> Bool {
        guard let settled = settled else { return false }
        return settled.blockchain.contains(chainId)
    }
    
    func hasPermission(forMethod method: String) -> Bool {
        guard let settled = settled else { return false }
        return settled.permissions.jsonrpc.methods.contains(method)
    }
    
    func hasPermission(forNotification type: String) -> Bool {
        guard let notificationPermissions = settled?.permissions.notifications else { return false }
        return notificationPermissions.types.contains(type)
    }
    
    mutating func upgrade(_ permissions: SessionPermissions) {
        settled?.permissions.upgrade(with: permissions)
    }
    
    mutating func update(_ accounts: Set<Account>) {
        settled?.accounts = accounts
    }
    
    mutating func extend(_ ttl: Int) throws {
        let newExpiryDate = Date(timeIntervalSinceNow: TimeInterval(ttl))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(SessionSequence.timeToLiveSettled))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidExtendTime
        }
        expiryDate = newExpiryDate
    }
}

extension SessionSequence {
    
    struct Pending: Codable {
        let status: Status
        let proposal: SessionProposal
        let outcomeTopic: String?
        
        enum Status: Codable {
            case proposed
            case responded
        }
    }
    
    struct Settled: Codable {
        let peer: Participant
        var permissions: SessionPermissions
        var accounts: Set<Account>
        var status: Status
        var blockchain: Set<String>

        enum Status: Codable {
            case preSettled
            case acknowledged
        }
    }
}

// MARK: - Initialization

extension SessionSequence {
    
    init(topic: String, relay: RelayProtocolOptions, selfParticipant: Participant, expiryDate: Date, pendingState: Pending) {
        self.init(topic: topic, relay: relay, selfParticipant: selfParticipant, expiryDate: expiryDate, sequenceState: .left(pendingState))
    }
    
    init(topic: String, relay: RelayProtocolOptions, selfParticipant: Participant, expiryDate: Date, settledState: Settled) {
        self.init(topic: topic, relay: relay, selfParticipant: selfParticipant, expiryDate: expiryDate, sequenceState: .right(settledState))
    }
    
    static func buildProposed(proposal: SessionProposal, topic: String) -> SessionSequence {
        SessionSequence(
            topic: topic,
            relay: proposal.relay,
            selfParticipant: Participant(publicKey: proposal.proposer.publicKey, metadata: proposal.proposer.metadata),
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(timeToLiveProposed)),
            pendingState: Pending(
                status: .proposed,
                proposal: proposal,
                outcomeTopic: nil
            )
        )
    }
    
    static func buildResponded(proposal: SessionProposal, agreementKeys: AgreementSecret, metadata: AppMetadata?, topic: String) -> SessionSequence {
        SessionSequence(
            topic: topic,
            relay: proposal.relay,
            selfParticipant: Participant(publicKey: agreementKeys.publicKey.hexRepresentation, metadata: metadata),
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(Time.day)),
            pendingState: Pending(
                status: .responded,
                proposal: proposal,
                outcomeTopic: agreementKeys.derivedTopic()
            )
        )
    }
    
    static func buildPreSettled(
        topic: String,
        proposal: SessionProposal,
        selfParticipant: Participant,
        metadata: AppMetadata,
        accounts: Set<Account>) -> SessionSequence {
            let controllerKey = selfParticipant.publicKey
            return SessionSequence(
                topic: topic,
                relay: proposal.relay,
                selfParticipant: selfParticipant,
                expiryDate: Date(timeIntervalSinceNow: TimeInterval(SessionSequence.timeToLiveSettled)),
                settledState: Settled(
                    peer: Participant(publicKey: proposal.proposer.publicKey, metadata: proposal.proposer.metadata),
                    permissions: SessionPermissions(
                        jsonrpc: proposal.permissions.jsonrpc,
                        notifications: proposal.permissions.notifications,
                        controller: AgreementPeer(publicKey: controllerKey)),
                    accounts: accounts,
                    status: .acknowledged,
                    blockchain: proposal.blockchainProposed.chains
                )
        )
    }
    
    static func buildAcknowledged(
        topic: String,
        settleParams : SessionType.SettleParams,
        selfParticipant: Participant,
        peerParticipant: Participant) -> SessionSequence {
            let controllerKey = settleParams.controller.publicKey
            return SessionSequence(
                topic: topic,
                relay: settleParams.relay,
                selfParticipant: selfParticipant,
                expiryDate: Date(timeIntervalSince1970: TimeInterval(settleParams.expiry)),
                settledState: Settled(
                    peer: peerParticipant,
                    permissions: SessionPermissions(
                        jsonrpc: settleParams.permissions.jsonrpc,
                        notifications: settleParams.permissions.notifications,
                        controller: AgreementPeer(publicKey: controllerKey)),
                    accounts: Set(settleParams.blockchain.accounts.compactMap { Account($0) }),
                    status: .acknowledged,
                    blockchain: settleParams.blockchain.chains
                )
            )
        }
    
    func publicRepresentation() -> Session? {
        guard let settled = self.settled else {return nil}
        return Session(
            topic: topic,
            peer: settled.peer.metadata!,
            permissions: Session.Permissions(methods: settled.permissions.jsonrpc.methods),
            accounts: settled.accounts,
            expiryDate: expiryDate,
            blockchains: settled.blockchain)
    }
}
