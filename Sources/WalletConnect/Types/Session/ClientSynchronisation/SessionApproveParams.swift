
import Foundation

extension SessionType {
    struct ApproveParams: Codable, Equatable {
        let relay: RelayProtocolOptions
        let responder: Participant
        let expiry: Int
        let state: State
    }
}
