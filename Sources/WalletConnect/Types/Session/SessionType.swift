import Foundation
import WalletConnectUtils

// Internal namespace for session payloads.
internal enum SessionType {
    
    typealias ProposeParams = SessionProposal
    
    struct ProposeResponse: Codable, Equatable {
        let relay: RelayProtocolOptions
        let publicKey: String
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
        private let accounts: Set<String>
        
        init(accounts: Set<Account>) {
            self.accounts = Set(accounts.map{$0.absoluteString})
        }
#if DEBUG
        init(accounts: Set<String>) {
            self.accounts = accounts
        }
#endif

        var isValidParam: Bool {
            return accounts.allSatisfy{String.conformsToCAIP10($0)}
        }
        
        func getAccounts() -> Set<Account> {
            return Set(accounts.compactMap{Account($0)})
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
