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

struct Subscription {

    var method: String {
        "subscription"
    }
}
