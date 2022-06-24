import WalletConnectUtils
import Foundation

/**
 A representation of an active session connection.
 */
public struct Session {
    public let topic: String
    public let peer: AppMetadata
    public let namespaces: [String: SessionNamespace]
    public let expiryDate: Date
    public static var defaultTimeToLive: Int64 {
        WCSession.defaultTimeToLive
    }
}

extension Session {

    public struct Proposal: Equatable {
        public var id: String
        public let proposer: AppMetadata
        public let requiredNamespaces: [String: ProposalNamespace]

        // TODO: Refactor internal objects to manage only needed data
        internal let proposal: SessionProposal
    }

    public struct Event: Equatable, Hashable {
        public let name: String
        public let data: AnyCodable

        internal func internalRepresentation() -> SessionType.EventParams.Event {
            SessionType.EventParams.Event(name: name, data: data)
        }
    }

}
