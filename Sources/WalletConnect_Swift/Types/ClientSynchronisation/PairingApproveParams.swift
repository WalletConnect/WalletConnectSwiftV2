// 

import Foundation

struct PairingApproveParams: Codable, Equatable {
    let topic: String
    
    enum CodingKeys: CodingKey {
        case topic
    }
}
