
import Foundation

struct SessionSettled: Codable {
    let topic: String
    let relay: RelayProtocolOptions
    let sharedKey: String
    let `self`: SessionParticipant
    let peer: SessionParticipant
    let permissions: SessionPermissions
    let expiry: Int
    let state: SessionState
}
