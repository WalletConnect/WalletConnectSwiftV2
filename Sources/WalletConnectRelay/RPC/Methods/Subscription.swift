
import Foundation
import WalletConnectUtils

struct Subscription: RelayRPC {

    struct Params: Codable {
        struct Contents: Codable {

            let topic: String
            let message: String
            let publishedAt: Date

            enum CodingKeys: String, CodingKey {
                case topic, message, publishedAt
            }

            internal init(topic: String, message: String, publishedAt: Date) {
                self.topic = topic
                self.message = message
                self.publishedAt = publishedAt
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                topic = try container.decode(String.self, forKey: .topic)
                message = try container.decode(String.self, forKey: .message)
                let publishedAtMiliseconds = try container.decode(UInt64.self, forKey: .publishedAt)
                publishedAt = Date(milliseconds: publishedAtMiliseconds)
            }
        }
        let id: String
        let data: Contents
    }

    let params: Params

    var method: String {
        "irn_subscription"
    }

    init(id: String, topic: String, message: String) {
        self.params = Params(id: id, data: Params.Contents(topic: topic, message: message, publishedAt: Date()))
    }
}
