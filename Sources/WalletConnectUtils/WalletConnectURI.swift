import Foundation

public struct WalletConnectURI: Equatable {

    public enum TargetAPI: String, CaseIterable {
        case sign
        case chat
        case auth
    }

    public let topic: String
    public let version: String
    public let symKey: String
    public let relay: RelayProtocolOptions

    public var api: TargetAPI {
        return apiType ?? .sign
    }

    public var absoluteString: String {
        if let api = apiType {
            return "wc:\(api.rawValue)-\(topic)@\(version)?symKey=\(symKey)&\(relayQuery)"
        }
        return "wc:\(topic)@\(version)?symKey=\(symKey)&\(relayQuery)"
    }

    private let apiType: TargetAPI?

    public init(topic: String, symKey: String, relay: RelayProtocolOptions, api: TargetAPI? = nil) {
        self.version = "2"
        self.topic = topic
        self.symKey = symKey
        self.relay = relay
        self.apiType = api
    }

    public init?(string: String) {
        guard let components = Self.parseURIComponents(from: string) else {
            return nil
        }
        let query: [String: String]? = components.queryItems?.reduce(into: [:]) { $0[$1.name] = $1.value }

        guard
            let userString = components.user,
            let version = components.host,
            let symKey = query?["symKey"],
            let relayProtocol = query?["relay-protocol"]
        else {
            return nil
        }
        let uriUser = Self.parseURIUser(from: userString)
        let relayData = query?["relay-data"]

        self.version = version
        self.topic = uriUser.topic
        self.symKey = symKey
        self.relay = RelayProtocolOptions(protocol: relayProtocol, data: relayData)
        self.apiType = uriUser.api
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

    private static func parseURIUser(from string: String) -> (topic: String, api: TargetAPI?) {
        let splits = string.split(separator: "-")
        if splits.count == 2, let apiFromPrefix = TargetAPI(rawValue: String(splits[0])) {
            return (String(splits[1]), apiFromPrefix)
        } else {
            return (string, nil)
        }
    }
}
