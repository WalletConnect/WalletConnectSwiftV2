import Foundation
import WalletConnectUtils

// Internal namespace for session payloads.
internal enum SessionType {
    
    typealias ProposeParams = SessionProposal
    
    struct ProposeResponse: Codable, Equatable {
        let relay: RelayProtocolOptions
        let responder: Participant
    }
    
    struct SettleParams: Codable, Equatable {
        let relay: RelayProtocolOptions
        let controller: Participant
        let accounts: Set<Account>
        let methods: Set<String>
        let events: Set<String>
        let expiry: Int64
    }
    
    struct UpdateAccountsParams: Codable, Equatable {
        private let accountsString: Set<String>
        var accounts: Set<Account> {
            return Set(accountsString.compactMap{Account($0)})
        }
        init(accounts: Set<Account>) {
            self.accountsString = Set(accounts.map{$0.absoluteString})
        }
        /// Initialiser for testing purposes only, allows to init invalid params,
        /// use `init(accounts: Set<Account>)` instead.
        init(accounts: Set<String>) {
            self.accountsString = accounts
        }
        var isValidParam: Bool {
            return accountsString.allSatisfy{String.conformsToCAIP10($0)}
        }
    }
    
    struct UpdateMethodsParams: Codable, Equatable {
        let methods: Set<String>
    }
    
    struct UpdateEventsParams: Codable, Equatable {
        let events: Set<String>
    }
    
    struct DeleteParams: Codable, Equatable {
        let reason: Reason
        init(reason: SessionType.Reason) {
            self.reason = reason
        }
    }
    
    struct Reason: Codable, Equatable {
        let code: Int
        let message: String
        
        init(code: Int, message: String) {
            self.code = code
            self.message = message
        }
    }
    
    struct RequestParams: Codable, Equatable {
        let request: Request
        let chainId: String?
        
        struct Request: Codable, Equatable {
            let method: String
            let params: AnyCodable
        }
    }
    
    struct EventParams: Codable, Equatable {
        let event: Event
        let chainId: String?

        struct Event: Codable, Equatable {
            let type: String
            let data: AnyCodable
        }
    }
    
    struct PingParams: Codable, Equatable {} 
    
    struct UpdateExpiryParams: Codable, Equatable {
        let expiry: Int64
    }
}

internal extension Reason {
    func internalRepresentation() -> SessionType.Reason {
        SessionType.Reason(code: self.code, message: self.message)
    }
}

extension SessionType.Reason {
    func publicRepresentation() -> Reason {
        Reason(code: self.code, message: self.message)
    }
}
