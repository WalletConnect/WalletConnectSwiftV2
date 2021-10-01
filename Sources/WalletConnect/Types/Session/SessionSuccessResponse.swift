
import Foundation

extension SessionType {
    typealias SuccessResponse = SessionType.ApproveParams
    struct State: Codable, Equatable {
        let accounts: [String]
    }
    
    public struct Participant: Codable, Equatable {
        let publicKey: String
        public let metadata: AppMetadata?
    }
}
