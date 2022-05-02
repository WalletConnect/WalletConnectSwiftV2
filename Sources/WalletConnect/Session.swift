import WalletConnectUtils
import Foundation

/**
 A representation of an active session connection.
 */
public struct Session {
    public let topic: String
    public let peer: AppMetadata
    public let namespaces: Set<Namespace>
    public let accounts: Set<Account>
    public let expiryDate: Date
    public static var defaultTimeToLive: Int64 {
        WCSession.defaultTimeToLive
    }
}

extension Session {
    
    public struct Proposal {
        public var id: String
        public let proposer: AppMetadata
        public let namespaces: Set<Namespace>
        
        // TODO: Refactor internal objects to manage only needed data
        internal let proposal: SessionProposal
    }

    public struct Event: Equatable, Hashable {
        public let name: String
        public let data: AnyCodable
        
        internal func internalRepresentation() -> SessionType.EventParams.Event{
            SessionType.EventParams.Event(name: name, data: data)
        }
    }
    
}
