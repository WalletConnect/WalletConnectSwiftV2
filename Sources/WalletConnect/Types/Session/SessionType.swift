import Foundation
import WalletConnectUtils

// Internal namespace for session payloads.
internal enum SessionType {
    
    typealias ProposeParams = SessionProposal
    
    struct ProposeResponse: Codable, Equatable {
        let relay: RelayProtocolOptions
        let responder: AgreementPeer
    }
    
    struct SettleParams: Codable, Equatable {
        let relay: RelayProtocolOptions
        let blockchain: Blockchain
        let permissions: SessionPermissions
        let controller: Participant
        let expiry: Int64
    }
    
    struct UpdateParams: Codable, Equatable {
        let state: SessionState
        
        init(state: SessionState) {
            self.state = state
        }
        
        init(accounts: Set<Account>) {
            let accountIds = accounts.map { $0.absoluteString }
            self.state = SessionState(accounts: accountIds)
        }
    }
    
    struct UpgradeParams: Codable, Equatable {
        let permissions: SessionPermissions
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
    
    struct NotificationParams: Codable, Equatable {
        let type: String
        let data: AnyCodable
        
        init(type: String, data: AnyCodable) {
            self.type = type
            self.data = data
        }
    }
    
    struct PingParams: Codable, Equatable {} 
    
    struct ExtendParams: Codable, Equatable {
        let expiry: Int64
    }
    
    struct Blockchain: Codable, Equatable {
        var chains: Set<String>
        var accounts: Set<Account>
    }
}

// A better solution could fit in here
internal extension Reason {
    func toInternal() -> SessionType.Reason {
        SessionType.Reason(code: self.code, message: self.message)
    }
}

extension SessionType.Reason {
    func toPublic() -> Reason {
        Reason(code: self.code, message: self.message)
    }
}
