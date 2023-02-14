
import Foundation

struct Publish: RelayRPC {

    struct Params: Codable {
        let topic: String
        let message: String
        let ttl: Int
        let prompt: Bool?
        let tag: Int?
    }

    let params: Params

    var method: String {
        "irn_publish"
    }
}

