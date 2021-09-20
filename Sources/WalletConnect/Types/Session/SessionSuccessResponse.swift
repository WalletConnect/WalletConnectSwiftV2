
import Foundation

extension SessionType {
    typealias SuccessResponse = SessionType.ApproveParams
    struct State: Codable, Equatable {
        let accounts: [String]
    }
    
    struct Participant: Codable, Equatable {
        let publicKey: String
        let metadata: AppMetadata
    }
}
