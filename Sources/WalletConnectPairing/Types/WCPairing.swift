import Foundation

public struct WCPairing: SequenceObject {
    enum Errors: Error {
        case invalidUpdateExpiryValue
    }

    public let topic: String
    public let relay: RelayProtocolOptions

    public private (set) var peerMetadata: AppMetadata?
    public private (set) var expiryDate: Date
    public private (set) var active: Bool
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
        self.active = false
        self.requestReceived = false
        self.methods = uri.methods
        self.expiryDate = Date(timeIntervalSince1970: TimeInterval(uri.expiryTimestamp))
    }

    public mutating func activate() {
        active = true
        try? updateExpiry()
    }
    
    public mutating func receivedRequest() {
        requestReceived = true
    }

    public mutating func updatePeerMetadata(_ metadata: AppMetadata?) {
        peerMetadata = metadata
    }

    public mutating func updateExpiry(_ ttl: TimeInterval = WCPairing.timeToLiveActive) throws {
        let now = Self.dateInitializer()
        let newExpiryDate = now.advanced(by: ttl)
        let maxExpiryDate = now.advanced(by: Self.timeToLiveActive)
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw Errors.invalidUpdateExpiryValue
        }
        expiryDate = newExpiryDate
    }
}

#if DEBUG
extension WCPairing {
    static func stub(expiryDate: Date = Date(timeIntervalSinceNow: 10000), isActive: Bool = true, topic: String = String.generateTopic()) -> WCPairing {
        WCPairing(topic: topic, relay: RelayProtocolOptions.stub(), peerMetadata: AppMetadata.stub(), isActive: isActive, expiryDate: expiryDate)
    }

    init(topic: String, relay: RelayProtocolOptions, peerMetadata: AppMetadata, isActive: Bool = false, requestReceived: Bool = false, expiryDate: Date) {
        self.topic = topic
        self.relay = relay
        self.peerMetadata = peerMetadata
        self.active = isActive
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
