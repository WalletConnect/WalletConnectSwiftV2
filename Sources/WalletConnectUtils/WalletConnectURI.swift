import Foundation

public struct WalletConnectURI: Equatable {
    public enum Errors: Error {
          case expired
          case invalidFormat
      }
    public let topic: String
    public let version: String
    public let symKey: String
    public let relay: RelayProtocolOptions
    public let methods: [String]?
    public let expiryTimestamp: UInt64

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
        self.expiryTimestamp = fiveMinutesFromNow
    }

    @available(*, deprecated, message: "Use the throwing initializer instead")
    public init?(string: String) {
        do {
            try self.init(uriString: string)
        } catch {
            print("Initialization failed: \(error.localizedDescription)")
            return nil
        }
    }

    public init(uriString: String) throws {
        let decodedString = uriString.removingPercentEncoding ?? uriString
        guard let components = Self.parseURIComponents(from: decodedString) else {
            throw Errors.invalidFormat
        }
        let query: [String: String]? = components.queryItems?.reduce(into: [:]) { $0[$1.name] = $1.value }

        guard
            let topic = components.user,
            let version = components.host,
            let symKey = query?["symKey"],
            let relayProtocol = query?["relay-protocol"]
        else {
            throw Errors.invalidFormat
        }

        let relayData = query?["relay-data"]
        let methodsString = query?["methods"]
        let methods = methodsString?.components(separatedBy: ",")

        // Check if expiryTimestamp is provided and valid
        if let expiryTimestampString = query?["expiryTimestamp"],
           let expiryTimestamp = UInt64(expiryTimestampString),
           expiryTimestamp <= UInt64(Date().timeIntervalSince1970) {
            throw Errors.expired
        }

        self.version = version
        self.topic = topic
        self.symKey = symKey
        self.relay = RelayProtocolOptions(protocol: relayProtocol, data: relayData)
        self.methods = methods
        self.expiryTimestamp = UInt64(query?["expiryTimestamp"] ?? "") ?? fiveMinutesFromNow
    }


    public init(deeplinkUri: URL) throws {
        let uriString = deeplinkUri.query?.replacingOccurrences(of: "uri=", with: "") ?? ""
        try self.init(uriString: uriString)
    }

    private var queryString: String {
        var parts = ["symKey=\(symKey)", "relay-protocol=\(relay.protocol)", "expiryTimestamp=\(expiryTimestamp)"]
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
        let decodedString = string.removingPercentEncoding ?? string
        guard decodedString.hasPrefix("wc:") else {
            return nil
        }

        let urlString = !decodedString.hasPrefix("wc://") ? decodedString.replacingOccurrences(of: "wc:", with: "wc://") : decodedString
        return URLComponents(string: urlString)
    }
}

extension WalletConnectURI.Errors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .expired:
            return NSLocalizedString("The WalletConnect Pairing URI has expired.", comment: "Expired URI Error")
        case .invalidFormat:
            return NSLocalizedString("The format of the WalletConnect Pairing URI is invalid.", comment: "Invalid Format URI Error")
        }
    }
}


fileprivate var fiveMinutesFromNow: UInt64 {
    return UInt64(Date().timeIntervalSince1970) + 5 * 60
}


#if canImport(UIKit)

import UIKit

extension WalletConnectURI {
    public init(connectionOptions: UIScene.ConnectionOptions) throws {
        if let uri = connectionOptions.urlContexts.first?.url.query?.replacingOccurrences(of: "uri=", with: "") {
            try self.init(uriString: uri)
        } else {
            throw Errors.invalidFormat
        }
    }
    
    public init(urlContext: UIOpenURLContext) throws {
        if let uri = urlContext.url.query?.replacingOccurrences(of: "uri=", with: "") {
            try self.init(uriString: uri)
        } else {
            throw Errors.invalidFormat
        }
    }
}
#endif

#if DEBUG
extension WalletConnectURI {
    init(topic: String, symKey: String, relay: RelayProtocolOptions, methods: [String]? = nil, expiryTimestamp: UInt64) {
        self.version = "2"
        self.topic = topic
        self.symKey = symKey
        self.relay = relay
        self.methods = methods
        self.expiryTimestamp = expiryTimestamp
    }
}
#endif
