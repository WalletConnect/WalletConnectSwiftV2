struct Subscribe: RelayRPC {

    struct Params: Codable {
        let topic: String
    }

    let params: Params

    var method: String {
        "subscribe"
    }
}

struct Unsubscribe: RelayRPC {

    struct Params: Codable {
        let id: String
        let topic: String
    }

    let params: Params

    var method: String {
        "unsubscribe"
    }
}

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
        "publish"
    }
}

struct Subscription: RelayRPC {

    struct Params: Codable {
        struct Contents: Codable {
            let topic: String
            let message: String
        }
        let id: String
        let data: Contents
    }

    let params: Params

    var method: String {
        "subscription"
    }

    init(id: String, topic: String, message: String) {
        self.params = Params(id: id, data: Params.Contents(topic: topic, message: message))
    }
}
