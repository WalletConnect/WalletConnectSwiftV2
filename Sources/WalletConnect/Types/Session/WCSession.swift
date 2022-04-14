import Foundation
import WalletConnectKMS

struct WCSession: ExpirableSequence {
    enum Error: Swift.Error {
        case controllerNotSet
    }
    let topic: String
    let pairingTopic: String
    let relay: RelayProtocolOptions
    let selfParticipant: Participant
    let peerParticipant: Participant
    private (set) var expiryDate: Date
    var acknowledged: Bool
    let controller: AgreementPeer
    private(set) var accounts: Set<Account>
    private(set) var methods: Set<String>
    private(set) var events: Set<String>
    
    static var defaultTimeToLive: Int64 {
        Int64(7*Time.day)
    }
    // for expirable...
    var publicKey: String? {
        selfParticipant.publicKey
    }
    
    init(topic: String,
         pairingTopic: String,
         selfParticipant: Participant,
         peerParticipant: Participant,
         settleParams: SessionType.SettleParams,
         acknowledged: Bool) {
        self.topic = topic
        self.relay = settleParams.relay
        self.controller = AgreementPeer(publicKey: settleParams.controller.publicKey)
        self.selfParticipant = selfParticipant
        self.peerParticipant = peerParticipant
        self.methods = settleParams.methods
        self.events = settleParams.events
        self.accounts = settleParams.accounts
        self.acknowledged = acknowledged
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(settleParams.expiry))
    }
    
#if DEBUG
    internal init(topic: String, relay: RelayProtocolOptions, controller: AgreementPeer, selfParticipant: Participant, peerParticipant: Participant, methods: Set<String>, events: Set<String>, accounts: Set<Account>, acknowledged: Bool, expiry: Int64) {
        self.topic = topic
        self.relay = relay
        self.controller = controller
        self.selfParticipant = selfParticipant
        self.peerParticipant = peerParticipant
        self.methods = methods
        self.events = events
        self.accounts = accounts
        self.acknowledged = acknowledged
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(expiry))
    }
#endif
    
    mutating func acknowledge() {
        self.acknowledged = true
    }
    
    var selfIsController: Bool {
        return controller.publicKey == selfParticipant.publicKey
    }
    
    var peerIsController: Bool {
        return controller.publicKey == peerParticipant.publicKey
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
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(WCSession.defaultTimeToLive))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidUpdateExpiryValue
        }
        expiryDate = newExpiryDate
    }
    
    /// updates session expiry to given timestamp
    /// - Parameter expiry: timestamp in the future in seconds
    mutating func updateExpiry(to expiry: Int64) throws {
        let newExpiryDate = Date(timeIntervalSince1970: TimeInterval(expiry))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(WCSession.defaultTimeToLive))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidUpdateExpiryValue
        }
        expiryDate = newExpiryDate
    }

    func publicRepresentation() -> Session {
        return Session(
            topic: topic,
            peer: peerParticipant.metadata,
            methods: methods,
            events: events,
            accounts: accounts,
            expiryDate: expiryDate)
    }
}
