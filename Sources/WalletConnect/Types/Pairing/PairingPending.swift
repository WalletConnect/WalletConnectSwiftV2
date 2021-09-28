
import Foundation

extension PairingType {
    struct Pending: Codable, SequencePending, Equatable {
        enum PendingStatus: String, Equatable, Codable {
            case proposed = "proposed"
            case responded = "responded"
        }
        let status: PendingStatus
        let topic: String
        let relay: RelayProtocolOptions
        let `self`: Participant
        let proposal: Proposal
    }
}
