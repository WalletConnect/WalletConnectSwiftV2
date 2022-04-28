import Foundation
import WalletConnectKMS

struct WCSession: ExpirableSequence {
    enum Error: Swift.Error {
        case controllerNotSet
    }
    let topic: String
    let relay: RelayProtocolOptions
    let selfParticipant: Participant
    let peerParticipant: Participant
    private (set) var expiryDate: Date
    var acknowledged: Bool
    let controller: AgreementPeer
    private(set) var accounts: Set<Account>
    private(set) var namespaces: Set<Namespace>
    
    static var defaultTimeToLive: Int64 {
        Int64(7*Time.day)
    }
    // for expirable...
    var publicKey: String? {
        selfParticipant.publicKey
    }
    
    init(topic: String,
         selfParticipant: Participant,
         peerParticipant: Participant,
         settleParams: SessionType.SettleParams,
         acknowledged: Bool) {
        self.topic = topic
        self.relay = settleParams.relay
        self.controller = AgreementPeer(publicKey: settleParams.controller.publicKey)
        self.selfParticipant = selfParticipant
        self.peerParticipant = peerParticipant
        self.namespaces = settleParams.namespaces
        self.accounts = settleParams.accounts
        self.acknowledged = acknowledged
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(settleParams.expiry))
    }
    
#if DEBUG
    internal init(topic: String, relay: RelayProtocolOptions, controller: AgreementPeer, selfParticipant: Participant, peerParticipant: Participant, namespaces: Set<Namespace>, events: Set<String>, accounts: Set<Account>, acknowledged: Bool, expiry: Int64) {
        self.topic = topic
        self.relay = relay
        self.controller = controller
        self.selfParticipant = selfParticipant
        self.peerParticipant = peerParticipant
        self.namespaces = namespaces
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
    
    func hasPermission(for chain: Blockchain) -> Bool {
        namespaces.contains{$0.chains.contains(chain)}
    }
    
    func hasPermission(for chain: Blockchain, method: String) -> Bool {
        let namespacesIncludingChain = namespaces.filter{$0.chains.contains(chain)}
        let methods = namespacesIncludingChain.flatMap{$0.methods}
        return methods.contains(method)
    }
    
    func hasNamespace(for chain: Blockchain?,  event: String) -> Bool {
        if let chain = chain {
            if let namespace = namespaces.first(where: {$0.chains.contains(chain)}),
               namespace.events.contains(event) {
                return true
            } else {
                return false
            }
        } else {
            if let namespace = namespaces.first(where: {$0.chains.isEmpty}),
               namespace.events.contains(event) {
                return true
            } else {
                return false
            }
        }
    }

    mutating func updateAccounts(_ accounts: Set<Account>) {
        self.accounts = accounts
    }
    
    mutating func updateNamespaces(_ namespaces: Set<Namespace>) {
        self.namespaces = namespaces
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
            namespaces: namespaces,
            accounts: accounts,
            expiryDate: expiryDate)
    }
}
