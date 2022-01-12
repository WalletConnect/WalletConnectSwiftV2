
import Foundation

internal enum PairingType {
    struct ApprovalParams: Codable, Equatable {
        let relay: RelayProtocolOptions
        let responder: PairingParticipant
        let expiry: Int
        let state: PairingState?
    }
}

//struct PairingApproval: Codable, Equatable {
//    let relay: RelayProtocolOptions
//    let responder: PairingParticipant
//    let expiry: Int
//    let state: PairingState?
//}
