
import Foundation

typealias SessionSuccessResponse = SessionApproveParams

struct SessionState: Codable {
    let accounts: [String]
}

struct SessionParticipant: Codable {
    let publicKey: String
    let metadata: AppMetadata
}

