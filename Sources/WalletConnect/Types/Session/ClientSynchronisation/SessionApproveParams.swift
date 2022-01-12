
import Foundation

extension SessionType {
    struct ApproveParams: Codable, Equatable {
        let relay: RelayProtocolOptions
        let responder: SessionParticipant
        let expiry: Int
        let state: SessionState
    }
}
