

import Foundation

struct Invite: Codable {
    let pubKey: String
    let openingMessage: String
    
    var id: String {
        return pubKey
    }
}


