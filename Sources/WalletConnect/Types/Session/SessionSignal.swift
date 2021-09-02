// 

import Foundation

struct SessionSignal: Codable {
    struct Params: Codable {
        let topic: String
    }
    let method: String
    let params: Params
}


