// 

import Foundation

struct PairingApproveParams: Codable, Equatable {
    let topic: String
    let relay: RelayProtocolOptions
    let responder: PairingParticipant
    let expiry: Int
    let state: PairingState
    
    enum CodingKeys: CodingKey {
        case topic
        case relay
        case responder
        case expiry
        case state
    }

}
