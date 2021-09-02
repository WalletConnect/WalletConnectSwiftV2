
import Foundation

struct PairingSettled: Codable {
    let topic: String
    let relay: RelayProtocolOptions
    let sharedKey: String
    let `self`: PairingParticipant
    let peer: PairingParticipant
    let permissions: PairingPermissions
    let expiry: Int
    let state: PairingState
}
