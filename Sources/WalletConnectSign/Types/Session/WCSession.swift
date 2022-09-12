import Foundation
import WalletConnectKMS
import WalletConnectUtils

struct WCSession: SequenceObject, Equatable {
    enum Error: Swift.Error {
        case controllerNotSet
        case unsatisfiedUpdateNamespaceRequirement
    }

    let topic: String
    let relay: RelayProtocolOptions
    let selfParticipant: Participant
    let peerParticipant: Participant
    let controller: AgreementPeer

    private(set) var acknowledged: Bool
    private(set) var expiryDate: Date
    private(set) var timestamp: Date
    private(set) var namespaces: [String: SessionNamespace]
    private(set) var requiredNamespaces: [String: ProposalNamespace]

    static var defaultTimeToLive: Int64 {
        Int64(7*Time.day)
    }
    // for expirable...
    var publicKey: String? {
        selfParticipant.publicKey
    }

    init(topic: String,
         timestamp: Date,
         selfParticipant: Participant,
         peerParticipant: Participant,
         settleParams: SessionType.SettleParams,
         requiredNamespaces: [String: ProposalNamespace],
         acknowledged: Bool) {
        self.topic = topic
        self.timestamp = timestamp
        self.relay = settleParams.relay
        self.controller = AgreementPeer(publicKey: settleParams.controller.publicKey)
        self.selfParticipant = selfParticipant
        self.peerParticipant = peerParticipant
        self.namespaces = settleParams.namespaces
        self.requiredNamespaces = requiredNamespaces
        self.acknowledged = acknowledged
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(settleParams.expiry))
    }

#if DEBUG
    internal init(
        topic: String,
        timestamp: Date,
        relay: RelayProtocolOptions,
        controller: AgreementPeer,
        selfParticipant: Participant,
        peerParticipant: Participant,
        namespaces: [String: SessionNamespace],
        requiredNamespaces: [String: ProposalNamespace],
        events: Set<String>,
        accounts: Set<Account>,
        acknowledged: Bool,
        expiry: Int64
    ) {
        self.topic = topic
        self.timestamp = timestamp
        self.relay = relay
        self.controller = controller
        self.selfParticipant = selfParticipant
        self.peerParticipant = peerParticipant
        self.namespaces = namespaces
        self.requiredNamespaces = requiredNamespaces
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

    mutating func updateNamespaces(_ namespaces: [String: SessionNamespace], timestamp: Date = Date()) throws {
        for item in requiredNamespaces {
            guard
                let compliantNamespace = namespaces[item.key],
                SessionNamespace.accountsAreCompliant(compliantNamespace.accounts, toChains: item.value.chains),
                compliantNamespace.methods.isSuperset(of: item.value.methods),
                compliantNamespace.events.isSuperset(of: item.value.events)
            else {
                throw Error.unsatisfiedUpdateNamespaceRequirement
            }
            if let extensions = item.value.extensions {
                guard let compliantExtensions = compliantNamespace.extensions else {
                    throw Error.unsatisfiedUpdateNamespaceRequirement
                }
                for existingExtension in extensions {
                    guard compliantExtensions.contains(where: { $0.isCompliant(to: existingExtension) }) else {
                        throw Error.unsatisfiedUpdateNamespaceRequirement
                    }
                }
            }
        }
        self.namespaces = namespaces
        self.timestamp = timestamp
    }

    /// updates session expiry by given ttl
    /// - Parameter ttl: time the session expiry should be updated by - in seconds
    mutating func updateExpiry(by ttl: Int64) throws {
        let newExpiryDate = Date(timeIntervalSinceNow: TimeInterval(ttl))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(WCSession.defaultTimeToLive))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidUpdateExpiryValue
        }
        self.expiryDate = newExpiryDate
    }

    /// updates session expiry to given timestamp
    /// - Parameter expiry: timestamp in the future in seconds
    mutating func updateExpiry(to expiry: Int64) throws {
        let newExpiryDate = Date(timeIntervalSince1970: TimeInterval(expiry))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(WCSession.defaultTimeToLive))
        guard newExpiryDate >= expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidUpdateExpiryValue
        }
        self.expiryDate = newExpiryDate
    }

    func publicRepresentation() -> Session {
        return Session(
            topic: topic,
            peer: peerParticipant.metadata,
            namespaces: namespaces,
            expiryDate: expiryDate)
    }
}

// MARK: Codable Migration

extension WCSession {

    enum CodingKeys: String, CodingKey {
        case topic, relay, selfParticipant, peerParticipant, expiryDate, acknowledged, controller, namespaces, timestamp, requiredNamespaces
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.topic = try container.decode(String.self, forKey: .topic)
        self.relay = try container.decode(RelayProtocolOptions.self, forKey: .relay)
        self.controller = try container.decode(AgreementPeer.self, forKey: .controller)
        self.selfParticipant = try container.decode(Participant.self, forKey: .selfParticipant)
        self.peerParticipant = try container.decode(Participant.self, forKey: .peerParticipant)
        self.namespaces = try container.decode([String: SessionNamespace].self, forKey: .namespaces)
        self.acknowledged = try container.decode(Bool.self, forKey: .acknowledged)
        self.expiryDate = try container.decode(Date.self, forKey: .expiryDate)

        // Migration beta.102
        self.timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? .distantPast
        self.requiredNamespaces = try container.decodeIfPresent([String: ProposalNamespace].self, forKey: .requiredNamespaces) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(topic, forKey: .topic)
        try container.encode(relay, forKey: .relay)
        try container.encode(controller, forKey: .controller)
        try container.encode(selfParticipant, forKey: .selfParticipant)
        try container.encode(peerParticipant, forKey: .peerParticipant)
        try container.encode(namespaces, forKey: .namespaces)
        try container.encode(acknowledged, forKey: .acknowledged)
        try container.encode(expiryDate, forKey: .expiryDate)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(requiredNamespaces, forKey: .requiredNamespaces)
    }
}
