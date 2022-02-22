import Foundation

public struct WalletConnectURI: Equatable {
    
    let topic: String
    let version: String
    let symKey: String
    let relayProtocol: String
    let relayData: String?
    
    init(topic: String, symKey: String, relayProtocol: String, relayData: String? = nil) {
        self.version = "2"
        self.topic = topic
        self.symKey = symKey
        self.relayProtocol = relayProtocol
        self.relayData = relayData
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
              let relayProtocol = query?["relay-protocol"],
        else { return nil }
        self.relayData = query?["relay-data"]
        self.version = version
        self.topic = topic
        self.symKey = symKey
        self.relay = relay
    }
    
    public var absoluteString: String {
        return "wc:\(topic)@\(version)?symKey=\(symKey)&\(relayQuery)"
    }
    
    private var relayQuery() -> String {
        var query = "relay-protocol=\(relayProtocol)"
        if let relayData = relayData {
            query = "\(query)&relay-data=\(relayData)"
        }
        return query
    }
}
