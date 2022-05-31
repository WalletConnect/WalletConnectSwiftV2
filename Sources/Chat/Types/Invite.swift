

import Foundation

struct Invite: Codable {
    let pubKey: String
    let message: String
    
    var id: String {
        return pubKey
    }
}


