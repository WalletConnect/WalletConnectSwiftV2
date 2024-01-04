import Foundation

public struct WalletConnectURI: Equatable {
    public let topic: String
    public let version: String
    public let symKey: String
    public let relay: RelayProtocolOptions
    public let methods: [String]?

    public var absoluteString: String {
        return "wc:\(topic)@\(version)?\(queryString)"
    }

    public var deeplinkUri: String {
        return absoluteString
            .addingPercentEncoding(withAllowedCharacters: .rfc3986) ?? absoluteString
    }

    public init(topic: String, symKey: String, relay: RelayProtocolOptions, methods: [String]? = nil) {
        self.version = "2"
        self.topic = topic
        self.symKey = symKey
        self.relay = relay
        self.methods = methods
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
        let methodsString = query?["methods"]
        let methods = methodsString?.components(separatedBy: ",")

        self.version = version
        self.topic = topic
        self.symKey = symKey
        self.relay = RelayProtocolOptions(protocol: relayProtocol, data: relayData)
        self.methods = methods
    }

    public init?(deeplinkUri: URL) {
        if let deeplinkUri = deeplinkUri.query?.replacingOccurrences(of: "uri=", with: "") {
            self.init(string: deeplinkUri)
        } else {
            return nil
        }
    }

    private var queryString: String {
        var parts = ["symKey=\(symKey)", "relay-protocol=\(relay.protocol)"]
        if let relayData = relay.data {
            parts.append("relay-data=\(relayData)")
        }
        if let methods = methods {
            let encodedMethods = methods.joined(separator: ",")
            parts.append("methods=\(encodedMethods)")
        }
        return parts.joined(separator: "&")
    }

    private static func parseURIComponents(from string: String) -> URLComponents? {
        guard string.hasPrefix("wc:") else {
            return nil
        }
        var urlString = string
        if !string.hasPrefix("wc://") {
            urlString = string.replacingOccurrences(of: "wc:", with: "wc://")
        }
        return URLComponents(string: urlString)
    }
}



#if canImport(UIKit)

import UIKit

extension WalletConnectURI {
    public init?(connectionOptions: UIScene.ConnectionOptions) {
        if let uri = connectionOptions.urlContexts.first?.url.query?.replacingOccurrences(of: "uri=", with: "") {
            self.init(string: uri)
        } else {
            return nil
        }
    }
    
    public init?(urlContext: UIOpenURLContext) {
        if let uri = urlContext.url.query?.replacingOccurrences(of: "uri=", with: "") {
            self.init(string: uri)
        } else {
            return nil
        }
    }
}

#endif
