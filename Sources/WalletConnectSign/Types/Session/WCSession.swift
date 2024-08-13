import Foundation

struct WCSession: SequenceObject, Equatable {
    public enum TransportType: Codable {
        case relay
        case linkMode
    }
    enum Error: Swift.Error {
        case controllerNotSet
        case unsatisfiedUpdateNamespaceRequirement
    }

    let topic: String
    let pairingTopic: String
    let relay: RelayProtocolOptions
    let selfParticipant: Participant
    let peerParticipant: Participant
    let controller: AgreementPeer
    var transportType: TransportType
    var verifyContext: VerifyContext?

    private(set) var acknowledged: Bool
    private(set) var expiryDate: Date
    private(set) var timestamp: Date
    private(set) var namespaces: [String: SessionNamespace]
    private(set) var requiredNamespaces: [String: ProposalNamespace]
    private(set) var sessionProperties: [String: String]?

    static var defaultTimeToLive: Int64 {
        Int64(7*Time.day)
    }
    // for expirable...
    var publicKey: String? {
        selfParticipant.publicKey
    }

    init(topic: String,
         pairingTopic: String,
         timestamp: Date,
         selfParticipant: Participant,
         peerParticipant: Participant,
         settleParams: SessionType.SettleParams,
         requiredNamespaces: [String: ProposalNamespace],
         acknowledged: Bool,
         transportType: TransportType,
         verifyContext: VerifyContext?
    ) {
        self.topic = topic
        self.pairingTopic = pairingTopic
        self.timestamp = timestamp
        self.relay = settleParams.relay
        self.controller = AgreementPeer(publicKey: settleParams.controller.publicKey)
        self.selfParticipant = selfParticipant
        self.peerParticipant = peerParticipant
        self.namespaces = settleParams.namespaces
        self.sessionProperties = settleParams.sessionProperties
        self.requiredNamespaces = requiredNamespaces
        self.acknowledged = acknowledged
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(settleParams.expiry))
        self.transportType = transportType
        self.verifyContext = verifyContext
    }

#if DEBUG
    internal init(
        topic: String,
        pairingTopic: String,
        timestamp: Date,
        relay: RelayProtocolOptions,
        controller: AgreementPeer,
        selfParticipant: Participant,
        peerParticipant: Participant,
        namespaces: [String: SessionNamespace],
        sessionProperties: [String: String],
        requiredNamespaces: [String: ProposalNamespace],
        events: Set<String>,
        accounts: Set<Account>,
        acknowledged: Bool,
        expiryTimestamp: Int64,
        transportType: TransportType,
        verifyContext: VerifyContext
    ) {
        self.topic = topic
        self.pairingTopic = pairingTopic
        self.timestamp = timestamp
        self.relay = relay
        self.controller = controller
        self.selfParticipant = selfParticipant
        self.peerParticipant = peerParticipant
        self.namespaces = namespaces
        self.sessionProperties = sessionProperties
        self.requiredNamespaces = requiredNamespaces
        self.acknowledged = acknowledged
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(expiryTimestamp))
        self.transportType = transportType
        self.verifyContext = verifyContext
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
        return namespaces[chain.namespace] != nil || namespaces[chain.namespace + ":\(chain.reference)"] != nil
    }

    func hasPermission(forMethod method: String, onChain chain: Blockchain) -> Bool {
        if let namespace = namespaces[chain.namespace] {
            if namespace.accounts.contains(where: { $0.blockchain == chain }) {
                if namespace.methods.contains(method) {
                    return true
                }
            }
        }
        if let namespace = namespaces[chain.namespace + ":\(chain.reference)"] {
            if namespace.accounts.contains(where: { $0.blockchain == chain }) {
                if namespace.methods.contains(method) {
                    return true
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
            }
        }
        return false
    }

    mutating func updateNamespaces(_ namespaces: [String: SessionNamespace], timestamp: Date = Date()) throws {
        for item in requiredNamespaces {
            guard
                let compliantNamespace = namespaces[item.key],
                SessionNamespace.accountsAreCompliant(compliantNamespace.accounts, toChains: item.value.chains!),
                compliantNamespace.methods.isSuperset(of: item.value.methods),
                compliantNamespace.events.isSuperset(of: item.value.events)
            else {
                throw Error.unsatisfiedUpdateNamespaceRequirement
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
        guard newExpiryDate.millisecondsSince1970 >= (expiryDate.millisecondsSince1970 / 1000) && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidUpdateExpiryValue
        }
        self.expiryDate = newExpiryDate
    }

    func publicRepresentation() -> Session {
        return Session(
            topic: topic,
            pairingTopic: pairingTopic,
            peer: peerParticipant.metadata,
            requiredNamespaces: requiredNamespaces,
            namespaces: namespaces,
            sessionProperties: sessionProperties,
            expiryDate: expiryDate
        )
    }
}

// MARK: Codable Migration

extension WCSession {

    enum CodingKeys: String, CodingKey {
        case topic, pairingTopic, relay, selfParticipant, peerParticipant, expiryDate, acknowledged, controller, namespaces, timestamp, requiredNamespaces, sessionProperties, transportType, verifyContext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.topic = try container.decode(String.self, forKey: .topic)
        self.relay = try container.decode(RelayProtocolOptions.self, forKey: .relay)
        self.controller = try container.decode(AgreementPeer.self, forKey: .controller)
        self.selfParticipant = try container.decode(Participant.self, forKey: .selfParticipant)
        self.peerParticipant = try container.decode(Participant.self, forKey: .peerParticipant)
        self.namespaces = try container.decode([String: SessionNamespace].self, forKey: .namespaces)
        self.sessionProperties = try container.decodeIfPresent([String: String].self, forKey: .sessionProperties)
        self.acknowledged = try container.decode(Bool.self, forKey: .acknowledged)
        self.expiryDate = try container.decode(Date.self, forKey: .expiryDate)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.requiredNamespaces = try container.decode([String: ProposalNamespace].self, forKey: .requiredNamespaces)
        self.pairingTopic = try container.decode(String.self, forKey: .pairingTopic)
        self.transportType = (try? container.decode(TransportType.self, forKey: .transportType)) ?? .relay
        self.verifyContext = try? container.decode(VerifyContext.self, forKey: .verifyContext)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(topic, forKey: .topic)
        try container.encode(pairingTopic, forKey: .pairingTopic)
        try container.encode(relay, forKey: .relay)
        try container.encode(controller, forKey: .controller)
        try container.encode(selfParticipant, forKey: .selfParticipant)
        try container.encode(peerParticipant, forKey: .peerParticipant)
        try container.encode(namespaces, forKey: .namespaces)
        try container.encode(sessionProperties, forKey: .sessionProperties)
        try container.encode(acknowledged, forKey: .acknowledged)
        try container.encode(expiryDate, forKey: .expiryDate)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(requiredNamespaces, forKey: .requiredNamespaces)
        try container.encode(transportType, forKey: .transportType)
        try container.encode(verifyContext, forKey: .verifyContext)
    }
}
