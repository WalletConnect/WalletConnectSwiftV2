
import Foundation

extension PairingType {
    typealias SuccessResponse = PairingType.ApproveParams
    
    struct State: Codable, Equatable {
        var metadata: AppMetadata
    }
    
    public struct Participant: Codable, Equatable {
        let publicKey: String
        
        init(publicKey: String) {
            self.publicKey = publicKey
        }
    }
}
