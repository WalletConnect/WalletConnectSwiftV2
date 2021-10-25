import Foundation

struct WalletConnectURI: Equatable {
    
    let topic: String
    let version: String
    let publicKey: String
    let isController: Bool
    let relay: RelayProtocolOptions
    
    init(topic: String, publicKey: String, isController: Bool, relay: RelayProtocolOptions) {
        self.version = "2"
        self.topic = topic
        self.publicKey = publicKey
        self.isController = isController
        self.relay = relay
    }
    
    init?(string: String) {
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
              let publicKey = query?["publicKey"],
              let isController = Bool(query?["controller"] ?? ""),
              let relayOptions = query?["relay"],
              let relay = try? JSONDecoder().decode(RelayProtocolOptions.self, from: Data(relayOptions.utf8))
        else { return nil }
        
        self.version = version
        self.topic = topic
        self.publicKey = publicKey
        self.isController = isController
        self.relay = relay
    }
    
    var absoluteString: String {
        return "wc:\(topic)@\(version)?controller=\(isController)&publicKey=\(publicKey)&relay=\(relay.asPercentEncodedString())"
    }
}
