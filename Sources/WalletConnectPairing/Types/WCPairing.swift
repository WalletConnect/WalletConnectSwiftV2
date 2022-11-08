import Foundation

public struct WCPairing: SequenceObject {
    enum Errors: Error {
        case invalidUpdateExpiryValue
    }

    public let topic: String
    public let relay: RelayProtocolOptions
    public var peerMetadata: AppMetadata?

    public private (set) var expiryDate: Date
    public private (set) var active: Bool

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

    public init(topic: String, relay: RelayProtocolOptions, peerMetadata: AppMetadata, isActive: Bool = false, expiryDate: Date) {
        self.topic = topic
        self.relay = relay
        self.peerMetadata = peerMetadata
        self.active = isActive
        self.expiryDate = expiryDate
    }

    public init(topic: String) {
        self.topic = topic
        self.relay = RelayProtocolOptions(protocol: "irn", data: nil)
        self.active = false
        self.expiryDate = Self.dateInitializer().advanced(by: Self.timeToLiveInactive)
    }

    public init(uri: WalletConnectURI) {
        self.topic = uri.topic
        self.relay = uri.relay
        self.active = false
        self.expiryDate = Self.dateInitializer().advanced(by: Self.timeToLiveInactive)
    }

    public mutating func activate() {
        active = true
        try? updateExpiry()
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
