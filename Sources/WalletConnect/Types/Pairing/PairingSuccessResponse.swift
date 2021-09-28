
import Foundation

extension PairingType {
    typealias SuccessResponse = PairingType.ApproveParams
    
    struct State: Codable, Equatable {
        let metadata: AppMetadata
    }
    
    struct Participant:Codable, Equatable {
        let publicKey: String
        let metadata: AppMetadata?
        
        init(publicKey: String, metadata: AppMetadata? = nil) {
            self.publicKey = publicKey
            self.metadata = metadata
        }
    }
}
