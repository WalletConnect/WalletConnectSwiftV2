
import Foundation

extension SessionType {
    struct ApproveParams: Codable, Equatable {
        let topic: String
        let relay: RelayProtocolOptions
        let responder: Participant
        let expiry: Int
        let state: State
    }
}
