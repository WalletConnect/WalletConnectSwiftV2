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
    public let expiryTimestamp: UInt64

    public var absoluteString: String {
        return "wc:\(topic)@\(version)?symKey=\(symKey)&\(relayQuery)&expiryTimestamp=\(expiryTimestamp)"
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

        // Only after all properties are initialized, you can use self or its methods
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
        // Set expiryTimestamp to 5 minutes in the future if not included in the uri
        self.expiryTimestamp = UInt64(query?["expiryTimestamp"] ?? "") ?? fiveMinutesFromNow

    }


    public init(deeplinkUri: URL) throws {
        let uriString = deeplinkUri.query?.replacingOccurrences(of: "uri=", with: "") ?? ""
        try self.init(uriString: uriString)
    }

    private var relayQuery: String {
        var query = "relay-protocol=\(relay.protocol)"
        if let relayData = relay.data {
            query = "\(query)&relay-data=\(relayData)"
        }
        return query
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
    init(topic: String, symKey: String, relay: RelayProtocolOptions, expiryTimestamp: UInt64) {
        self.version = "2"
        self.topic = topic
        self.symKey = symKey
        self.relay = relay
        self.expiryTimestamp = expiryTimestamp
    }

}
#endif
