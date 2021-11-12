
import Foundation

extension SessionType {
    typealias SuccessResponse = SessionType.ApproveParams
    struct State: Codable, Equatable {
        var accounts: Set<String>
    }
    
    public struct Participant: Codable, Equatable {
        let publicKey: String
        public let metadata: AppMetadata
    }
}
