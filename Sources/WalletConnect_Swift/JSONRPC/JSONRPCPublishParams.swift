// 

import Foundation

struct JSONRPCPublishParams: Codable {
    let topic: String
    let message: String
    let ttl: Int
}
