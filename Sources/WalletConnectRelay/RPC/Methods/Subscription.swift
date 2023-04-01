import Foundation

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

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: Subscription.Params.Contents.CodingKeys.self)
                try container.encode(self.topic, forKey: Subscription.Params.Contents.CodingKeys.topic)
                try container.encode(self.message, forKey: Subscription.Params.Contents.CodingKeys.message)
                let publishedAtmilliseconds = publishedAt.millisecondsSince1970
                try container.encode(publishedAtmilliseconds, forKey: Subscription.Params.Contents.CodingKeys.publishedAt)
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
