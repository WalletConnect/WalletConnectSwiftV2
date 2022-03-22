import WalletConnectUtils
import Foundation

/**
 A representation of an active session connection.
 */
public struct Session {
    public let topic: String
    public let peer: AppMetadata
    public let permissions: Permissions
    public let accounts: Set<Account>
    public let expiryDate: Date
    public let blockchains: Set<String>
    public static var defaultTimeToLive: Int64 {
        SessionSequence.defaultTimeToLive
    }
}

extension Session {
    
    public struct Proposal {
        public let proposer: AppMetadata
        public let permissions: Permissions
        public let blockchains: Set<String>
        
        // TODO: Refactor internal objects to manage only needed data
        internal let proposal: SessionProposal
    }
    
    public struct Permissions: Equatable {
        public let methods: Set<String>
        public let notifications: Set<String>
        
        public init(methods: Set<String>, notifications: Set<String> = []) {
            self.methods = methods
            self.notifications = notifications
        }
        
        internal init (permissions: SessionPermissions) {
            self.methods = permissions.jsonrpc.methods
            self.notifications = permissions.notifications?.types ?? []
        }
    }

    public struct Notification: Equatable {
        public let type: String
        public let data: AnyCodable
    }
}
