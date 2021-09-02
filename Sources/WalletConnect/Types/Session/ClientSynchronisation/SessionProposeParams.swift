
import Foundation

struct SessionProposeParams: Codable {
    let topic: String
    let relay: RelayProtocolOptions
    let proposer: PairingProposer
    let signal: PairingSignal
    let permissions: SessionPermissions
    let ttl: Int
}

