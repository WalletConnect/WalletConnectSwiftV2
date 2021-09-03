
import Foundation

extension SessionType {
    struct ApproveParams: Codable {
        let topic: String
        let relay: RelayProtocolOptions
        let responder: Participant
        let expiry: Int
        let state: State
    }
}
