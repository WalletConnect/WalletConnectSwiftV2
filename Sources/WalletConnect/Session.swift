import WalletConnectUtils
import Foundation

/**
 A representation of an active session connection.
 */
public struct Session {
    public let topic: String
    public let peer: AppMetadata
    public let methods: Set<String>
    public let events: Set<String>
    public let accounts: Set<Account>
    public let expiryDate: Date
    public static var defaultTimeToLive: Int64 {
        SessionSequence.defaultTimeToLive
    }
}

extension Session {
    
    public struct Proposal {
        public let proposer: AppMetadata
        public let methods: Set<String>
        public let events: Set<String>
        public let blockchains: Set<String>
        
        // TODO: Refactor internal objects to manage only needed data
        internal let proposal: SessionProposal
    }

    public struct Notification: Equatable {
        public let type: String
        public let data: AnyCodable
    }
}
