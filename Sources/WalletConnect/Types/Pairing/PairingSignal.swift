// 

import Foundation

struct PairingSignal: Codable {
    struct Params: Codable {
        let uri: String
    }
    let type = "uri"
    let params: Params
}
