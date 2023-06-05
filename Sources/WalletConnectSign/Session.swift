import Foundation

/**
 A representation of an active session connection.
 */
public struct Session {
    public let topic: String
    public let pairingTopic: String
    public let peer: AppMetadata
    public let namespaces: [String: SessionNamespace]
    public let expiryDate: Date
    public static var defaultTimeToLive: Int64 {
        WCSession.defaultTimeToLive
    }
}

extension Session {

    public struct Proposal: Equatable, Codable {
        public var id: String
        public let pairingTopic: String
        public let proposer: AppMetadata
        public let requiredNamespaces: [String: ProposalNamespace]
        public let optionalNamespaces: [String: ProposalNamespace]?
        public let sessionProperties: [String: String]?

        // TODO: Refactor internal objects to manage only needed data
        internal let proposal: SessionProposal
    }

    public struct Event: Equatable, Hashable {
        public let name: String
        public let data: AnyCodable

        public init(name: String, data: AnyCodable) {
            self.name = name
            self.data = data
        }
        
        internal func internalRepresentation() -> SessionType.EventParams.Event {
            SessionType.EventParams.Event(name: name, data: data)
        }
    }
}
