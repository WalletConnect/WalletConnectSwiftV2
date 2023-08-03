import Foundation

public struct WalletConnectURI: Equatable {

    public let topic: String
    public let version: String
    public let symKey: String
    public let relay: RelayProtocolOptions

    public var absoluteString: String {
        return "wc:\(topic)@\(version)?symKey=\(symKey)&\(relayQuery)"
    }

    public var deeplinkUri: String {
        return absoluteString
            .addingPercentEncoding(withAllowedCharacters: .rfc3986) ?? absoluteString
    }

    public init(topic: String, symKey: String, relay: RelayProtocolOptions) {
        self.version = "2"
        self.topic = topic
        self.symKey = symKey
        self.relay = relay
    }

    public init?(string: String) {
        guard let components = Self.parseURIComponents(from: string) else {
            return nil
        }
        let query: [String: String]? = components.queryItems?.reduce(into: [:]) { $0[$1.name] = $1.value }

        guard
            let topic = components.user,
            let version = components.host,
            let symKey = query?["symKey"],
            let relayProtocol = query?["relay-protocol"]
        else {
            return nil
        }
        let relayData = query?["relay-data"]

        self.version = version
        self.topic = topic
        self.symKey = symKey
        self.relay = RelayProtocolOptions(protocol: relayProtocol, data: relayData)
    }

    private var relayQuery: String {
        var query = "relay-protocol=\(relay.protocol)"
        if let relayData = relay.data {
            query = "\(query)&relay-data=\(relayData)"
        }
        return query
    }

    private static func parseURIComponents(from string: String) -> URLComponents? {
        guard string.hasPrefix("wc:") else {
            return nil
        }
        let urlString = !string.hasPrefix("wc://") ? string.replacingOccurrences(of: "wc:", with: "wc://") : string
        return URLComponents(string: urlString)
    }
}
