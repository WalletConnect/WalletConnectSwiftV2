
import Foundation

typealias PairingSuccessResponse = PairingApproveParams

struct PairingState: Codable, Equatable {
    let metadata: AppMetadata
}

struct PairingParticipant:Codable, Equatable {
    let publicKey: String
}
