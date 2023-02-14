
import Foundation

struct Unsubscribe: RelayRPC {

    struct Params: Codable {
        let id: String
        let topic: String
    }

    let params: Params

    var method: String {
        "irn_unsubscribe"
    }
}

