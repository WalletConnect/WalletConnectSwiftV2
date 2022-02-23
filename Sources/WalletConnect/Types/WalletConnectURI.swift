import Foundation

public struct WalletConnectURI: Equatable {
    
    let topic: String
    let version: String
    let symmKey: String
    let relay: RelayProtocolOptions
    
    init(topic: String, symmKey: String, relay: RelayProtocolOptions) {
        self.version = "2"
        self.topic = topic
        self.symmKey = symmKey
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
              let symmKey = query?["symKey"],
              let relayProtocol = query?["relay-protocol"]
        else { return nil }
        self.version = version
        self.topic = topic
        self.symmKey = symmKey
        //todo - parse params
        self.relay = RelayProtocolOptions(protocol: relayProtocol, params: nil)
    }
    
    public var absoluteString: String {
        return "wc:\(topic)@\(version)?symKey=\(symmKey)&\(relayQuery)"
    }
    
    private var relayQuery: String {
        var query = "relay-protocol=\(relay.protocol)"
        if let params = relay.params {
//   todo -         parse params to data
//            query = "\(query)&relay-data=\(relayData)"
        }
        return query
    }
}
