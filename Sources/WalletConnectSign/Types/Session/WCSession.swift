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
    private(set) var namespaces: [String: SessionNamespace]
    
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
        self.acknowledged = acknowledged
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(settleParams.expiry))
    }
    
#if DEBUG
    internal init(topic: String, relay: RelayProtocolOptions, controller: AgreementPeer, selfParticipant: Participant, peerParticipant: Participant, namespaces: [String: SessionNamespace], events: Set<String>, accounts: Set<Account>, acknowledged: Bool, expiry: Int64) {
        self.topic = topic
        self.relay = relay
        self.controller = controller
        self.selfParticipant = selfParticipant
        self.peerParticipant = peerParticipant
        self.namespaces = namespaces
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
    
    func hasNamespace(for chain: Blockchain) -> Bool {
        return namespaces[chain.namespace] != nil
    }
    
    func hasPermission(forMethod method: String, onChain chain: Blockchain) -> Bool {
        if let namespace = namespaces[chain.namespace] {
            if namespace.accounts.contains(where: { $0.blockchain == chain }) {
                if namespace.methods.contains(method) {
                    return true
                }
                if let extensions = namespace.extensions {
                    for extended in extensions {
                        if extended.accounts.contains(where: { $0.blockchain == chain }) {
                            if extended.methods.contains(method) {
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }
    
    func hasPermission(forEvent event: String, onChain chain: Blockchain) -> Bool {
        if let namespace = namespaces[chain.namespace] {
            if namespace.accounts.contains(where: { $0.blockchain == chain }) {
                if namespace.events.contains(event) {
                    return true
                }
                if let extensions = namespace.extensions {
                    for extended in extensions {
                        if extended.accounts.contains(where: { $0.blockchain == chain }) {
                            if extended.events.contains(event) {
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }

    mutating func updateNamespaces(_ namespaces: [String: SessionNamespace]) {
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
            expiryDate: expiryDate)
    }
}
