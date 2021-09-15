
import Foundation

extension PairingType {
    struct Settled: Codable, SequenceSettled, Equatable {
        let topic: String
        let relay: RelayProtocolOptions
        let sharedKey: String
        let `self`: Participant
        let peer: Participant
        let permissions: Permissions
        let expiry: Int
        let state: State?
    }
    
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
