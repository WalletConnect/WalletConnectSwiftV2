import Foundation

public struct WCPairing: SequenceObject {
    enum Errors: Error {
        case invalidUpdateExpiryValue
    }

    public let topic: String
    public let relay: RelayProtocolOptions

    public private (set) var expiryDate: Date
    public private (set) var requestReceived: Bool
    public private (set) var methods: [String]?

    #if DEBUG
    public static var dateInitializer: () -> Date = Date.init
    #else
    private static var dateInitializer: () -> Date = Date.init
    #endif

    public static var timeToLiveInactive: TimeInterval {
        5 * .minute
    }

    public static var timeToLiveActive: TimeInterval {
        30 * .day
    }

    public init(uri: WalletConnectURI) {
        self.topic = uri.topic
        self.relay = uri.relay
        self.requestReceived = false
        self.methods = uri.methods
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(uri.expiryTimestamp))
    }
    
    public mutating func receivedRequest() {
        requestReceived = true
    }
}

#if DEBUG
extension WCPairing {
    static func stub(expiryDate: Date = Date(timeIntervalSinceNow: 10000), topic: String = String.generateTopic()) -> WCPairing {
        WCPairing(topic: topic, relay: RelayProtocolOptions.stub(), expiryDate: expiryDate)
    }

    init(topic: String, relay: RelayProtocolOptions, requestReceived: Bool = false, expiryDate: Date) {
        self.topic = topic
        self.relay = relay
        self.requestReceived = requestReceived
        self.expiryDate = expiryDate
    }
}

extension WalletConnectURI {
    public static func stub() -> WalletConnectURI {
        WalletConnectURI(
            topic: String.generateTopic(),
            symKey: SymmetricKey().hexRepresentation,
            relay: RelayProtocolOptions(protocol: "", data: nil),
            methods: ["wc_sessionPropose"]
        )
    }
}

#endif
