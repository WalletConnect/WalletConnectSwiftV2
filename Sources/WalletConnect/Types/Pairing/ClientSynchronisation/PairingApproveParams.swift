
import Foundation

struct PairingApproveParams: Codable, Equatable {
    let topic: String
    let relay: RelayProtocolOptions
    let responder: PairingParticipant
    let expiry: Int
    let state: PairingState
}
