
import Foundation
extension PairingType {
    struct Settled: Codable, Equatable {
        let topic: String
        let relay: RelayProtocolOptions
        let sharedKey: String
        let `self`: Participant
        let peer: Participant
        let permissions: Permissions
        let expiry: Int
        let state: State?
    }
    
    struct Pending: Equatable {
        enum PendingStatus: Equatable {
            case proposed
            case responded
        }
        let status: PendingStatus
        let topic: String
        let relay: RelayProtocolOptions
        let `self`: Participant
        let proposal: Proposal
    }
}

