
import Foundation

struct BatchSubscribe: RelayRPC {

    struct Params: Codable {
        let topics: [String]
    }

    let params: Params

    var method: String {
        "irn_batchSubscribe"
    }
}

