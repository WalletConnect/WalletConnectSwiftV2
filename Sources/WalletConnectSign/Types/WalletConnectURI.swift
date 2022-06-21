import Foundation

public struct WalletConnectURI: Equatable {

    let topic: String
    let version: String
    let symKey: String
    let relay: RelayProtocolOptions

    init(topic: String, symKey: String, relay: RelayProtocolOptions) {
        self.version = "2"
        self.topic = topic
        self.symKey = symKey
        self.relay = relay
    }

    public init?(string: String) {
        guard string.hasPrefix("wc:") else {
            return nil
        }
        let urlString = !string.hasPrefix("wc://") ? string.replacingOccurrences(of: "wc:", with: "wc://") : string
        guard let components = URLComponents(string: urlString) else {
            return nil
        }
        let query: [String: String]? = components.queryItems?.reduce(into: [:]) { $0[$1.name] = $1.value }

        guard let topic = components.user,
              let version = components.host,
              let symKey = query?["symKey"],
              let relayProtocol = query?["relay-protocol"]
        else { return nil }
        let relayData = query?["relay-data"]
        self.version = version
        self.topic = topic
        self.symKey = symKey
        self.relay = RelayProtocolOptions(protocol: relayProtocol, data: relayData)
    }

    public var absoluteString: String {
        return "wc:\(topic)@\(version)?symKey=\(symKey)&\(relayQuery)"
    }

    private var relayQuery: String {
        var query = "relay-protocol=\(relay.protocol)"
        if let relayData = relay.data {
            query = "\(query)&relay-data=\(relayData)"
        }
        return query
    }
}
