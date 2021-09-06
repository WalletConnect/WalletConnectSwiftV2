
import Foundation

extension SessionType {
    typealias SuccessResponse = SessionType.ApproveParams
    struct State: Codable {
        let accounts: [String]
    }
    
    struct Participant: Codable {
        let publicKey: String
        let metadata: AppMetadata
    }
}
