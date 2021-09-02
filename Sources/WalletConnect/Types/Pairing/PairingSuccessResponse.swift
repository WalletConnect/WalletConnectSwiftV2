
import Foundation

extension PairingType {
    typealias SuccessResponse = PairingType.ApproveParams
    
    struct State: Codable, Equatable {
        let metadata: AppMetadata
    }
    
    struct Participant:Codable, Equatable {
        let publicKey: String
    }
}
