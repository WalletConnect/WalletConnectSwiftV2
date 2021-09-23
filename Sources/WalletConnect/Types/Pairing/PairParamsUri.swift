
import Foundation

extension PairingType {
    public struct UriParameters {
        let version: String
        let topic: String
        let publicKey: String
        let controller: Bool
        let relay: RelayProtocolOptions
        
        init(version: String = "2", topic: String, publicKey: String, controller: Bool, relay: RelayProtocolOptions) {
            self.version = version
            self.topic = topic
            self.publicKey = publicKey
            self.controller = controller
            self.relay = relay
        }

        public init?(_ str: String) {
            guard str.hasPrefix("wc:") else {
                return nil
            }
            let urlStr = !str.hasPrefix("wc://") ? str.replacingOccurrences(of: "wc:", with: "wc://") : str
            guard let url = URL(string: urlStr),
                  let topic = url.user,
                  let version = url.host,
                  let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }
            var dict = [String: String]()
            for query in components.queryItems ?? [] {
                if let value = query.value {
                    dict[query.name] = value
                }
            }
            guard let publicKey = dict["publicKey"],
                  let relay = dict["relay"],
                  let controllerValue = dict["controller"],
                  let controller = Bool(controllerValue) else {
                return nil
            }
            self.topic = topic
            self.version = version
            self.publicKey = publicKey
            self.relay = try! JSONDecoder().decode(RelayProtocolOptions.self, from:  Data(relay.utf8))
            self.controller = controller
        }
        
        
        func absoluteString() -> String? {
            guard let relay = try? relay.json().addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
                return nil
            }
            return "wc:\(topic)@\(version)?controller=\(controller)&publicKey=\(publicKey)&relay=\(relay)"
        }
    }
}
