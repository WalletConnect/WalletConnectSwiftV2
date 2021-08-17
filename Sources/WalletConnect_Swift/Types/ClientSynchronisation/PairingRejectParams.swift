// 

import Foundation

struct PairingRejectParams: Codable, Equatable {
    let reason: String
    
    enum CodingKeys: CodingKey {
        case reason
    }
}
