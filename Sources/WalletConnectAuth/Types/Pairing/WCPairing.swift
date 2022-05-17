import Foundation
import WalletConnectKMS

struct WCPairing: ExpirableSequence {
    let topic: String
    let relay: RelayProtocolOptions
    var peerMetadata: AppMetadata?
    private (set) var expiryDate: Date
    private (set) var active: Bool
    
    #if DEBUG
    static var dateInitializer: () -> Date = Date.init
    #else
    private static var dateInitializer: () -> Date = Date.init
    #endif
    
    static var timeToLiveInactive: TimeInterval {
        5 * .minute
    }
    
    static var timeToLiveActive: TimeInterval {
        30 * .day
    }
    
    init(topic: String, relay: RelayProtocolOptions, peerMetadata: AppMetadata, isActive: Bool = false, expiryDate: Date) {
        self.topic = topic
        self.relay = relay
        self.peerMetadata = peerMetadata
        self.active = isActive
        self.expiryDate = expiryDate
    }
    
    init(topic: String) {
        self.topic = topic
        self.relay = RelayProtocolOptions(protocol: "waku", data: nil)
        self.active = false
        self.expiryDate = Self.dateInitializer().advanced(by: Self.timeToLiveInactive)
    }
    
    init(uri: WalletConnectURI) {
        self.topic = uri.topic
        self.relay = uri.relay
        self.active = false
        self.expiryDate = Self.dateInitializer().advanced(by: Self.timeToLiveInactive)
    }
    
    mutating func activate() {
        active = true
        try? updateExpiry()
    }
    
    mutating func updateExpiry(_ ttl: TimeInterval = WCPairing.timeToLiveActive) throws {
        let now = Self.dateInitializer()
        let newExpiryDate = now.advanced(by: ttl)
        let maxExpiryDate = now.advanced(by: Self.timeToLiveActive)
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidUpdateExpiryValue
        }
        expiryDate = newExpiryDate
    }
}
