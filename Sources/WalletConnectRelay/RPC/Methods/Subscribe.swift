struct Subscribe: RelayRPC {

    struct Params: Codable {
        let topic: String
    }

    let params: Params

    var method: String {
        "subscribe"
    }
}

