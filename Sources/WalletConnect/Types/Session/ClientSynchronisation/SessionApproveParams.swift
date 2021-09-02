
import Foundation

struct SessionApproveParams {
    let topic: String
    let relay: RelayProtocolOptions
    let responder: SessionParticipant
    let expiry: Int
    let state: SessionState
}
