import Foundation
import WalletConnectKMS

struct SessionSequence: ExpirableSequence {
    struct Participants: Codable, Equatable {
        let `self`: Participant
        let peer: Participant
    }
    enum Error: Swift.Error {
        case controllerNotSet
    }
    let topic: String
    let relay: RelayProtocolOptions
    let controller: AgreementPeer
    let participants: Participants

//    let `self`: Participant
//    let peer: Participant
    private(set) var methods: Set<String>
    private(set) var events: Set<String>
    private(set) var accounts: Set<Account>

    var acknowledged: Bool

    private (set) var expiryDate: Date
    
    static var defaultTimeToLive: Int64 {
        Int64(7*Time.day)
    }
    // for expirable...
    var publicKey: String? {
        participants.`self`.publicKey
    }
    
    init(topic: String,
         selfParticipant: Participant,
         peerParticipant: Participant,
         settleParams: SessionType.SettleParams,
         acknowledged: Bool) {
        self.topic = topic
        self.relay = settleParams.relay
        self.controller = AgreementPeer(publicKey: settleParams.controller.publicKey)
        self.participants = Participants(self: selfParticipant, peer: peerParticipant)

//        self.`self` = selfParticipant
//        self.peer = peerParticipant
        self.methods = settleParams.methods
        self.events = settleParams.events
        self.accounts = settleParams.accounts
        self.acknowledged = acknowledged
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(settleParams.expiry))
    }
    
    internal init(topic: String, relay: RelayProtocolOptions, controller: AgreementPeer, participants: SessionSequence.Participants, methods: Set<String>, events: Set<String>, accounts: Set<Account>, acknowledged: Bool, expiry: Int64) {
        self.topic = topic
        self.relay = relay
        self.controller = controller
        self.participants = participants
        self.methods = methods
        self.events = events
        self.accounts = accounts
        self.acknowledged = acknowledged
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(expiry))
    }
    
    mutating func acknowledge() {
        self.acknowledged = true
    }
    
    
    func getPublicKey() throws -> AgreementPublicKey {
        try AgreementPublicKey(rawRepresentation: Data(hex: participants.`self`.publicKey))
    }
    
    var selfIsController: Bool {
        return controller.publicKey == participants.`self`.publicKey
    }
    
    var peerIsController: Bool {
        return controller.publicKey == participants.peer.publicKey
    }
    
    var blockchains: [Blockchain] {
        return accounts.map{$0.blockchain}
    }
    
    func hasPermission(forChain chainId: String) -> Bool {
        return blockchains
            .map{$0.absoluteString}
            .contains(chainId)
    }
    
    func hasPermission(forMethod method: String) -> Bool {
        return methods.contains(method)
    }
    
    func hasPermission(forEvents type: String) -> Bool {
        return events.contains(type)
    }

    mutating func updateAccounts(_ accounts: Set<Account>) {
        self.accounts = accounts
    }
    
    mutating func updateMethods(_ methods: Set<String>) {
        self.methods = methods
    }
    
    mutating func updateEvents(_ events: Set<String>) {
        self.events = events
    }
    
    /// updates session expiry by given ttl
    /// - Parameter ttl: time the session expiry should be updated by - in seconds
    mutating func updateExpiry(by ttl: Int64) throws {
        let newExpiryDate = Date(timeIntervalSinceNow: TimeInterval(ttl))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(SessionSequence.defaultTimeToLive))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidUpdateExpiryValue
        }
        expiryDate = newExpiryDate
    }
    
    /// updates session expiry to given timestamp
    /// - Parameter expiry: timestamp in the future in seconds
    mutating func updateExpiry(to expiry: Int64) throws {
        let newExpiryDate = Date(timeIntervalSince1970: TimeInterval(expiry))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(SessionSequence.defaultTimeToLive))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidUpdateExpiryValue
        }
        expiryDate = newExpiryDate
    }

    func publicRepresentation() -> Session {
        return Session(
            topic: topic,
            peer: participants.peer.metadata,
            methods: methods,
            events: events,
            accounts: accounts,
            expiryDate: expiryDate)
    }
}
