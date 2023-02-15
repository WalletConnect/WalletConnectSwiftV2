
import Foundation
import WalletConnectUtils

struct Subscription: RelayRPC {

    struct Params: Codable {
        struct Contents: Codable {
            let topic: String
            let message: String
            let publishedAt: UInt64
        }
        let id: String
        let data: Contents
    }

    let params: Params

    var method: String {
        "irn_subscription"
    }

    init(id: String, topic: String, message: String) {
        self.params = Params(id: id, data: Params.Contents(topic: topic, message: message, publishedAt: Date().millisecondsSince1970))
    }
}
