import Foundation
import WalletConnectKMS

struct PairingSequence: ExpirableSequence {
    
    struct Participants: Codable, Equatable {
        var `self`: AppMetadata?
        var peer: AppMetadata?
    }
    
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
    
    let topic: String
    let relay: RelayProtocolOptions
    var participants: Participants
    
    private (set) var isActive: Bool
    private (set) var expiryDate: Date
    
    init(topic: String, relay: RelayProtocolOptions, participants: Participants, isActive: Bool = false, expiryDate: Date) {
        self.topic = topic
        self.relay = relay
        self.participants = participants
        self.isActive = isActive
        self.expiryDate = expiryDate
    }
    
    init(topic: String, selfMetadata: AppMetadata) {
        self.topic = topic
        self.relay = RelayProtocolOptions(protocol: "waku", data: nil)
        self.participants = Participants(self: selfMetadata, peer: nil)
        self.isActive = false
        self.expiryDate = Self.dateInitializer().advanced(by: Self.timeToLiveInactive)
    }
    
    init(uri: WalletConnectURI) {
        self.topic = uri.topic
        self.relay = uri.relay
        self.participants = Participants()
        self.isActive = false
        self.expiryDate = Self.dateInitializer().advanced(by: Self.timeToLiveInactive)
    }
    
    mutating func activate() {
        isActive = true
    }
    
    mutating func extend(_ ttl: TimeInterval = PairingSequence.timeToLiveActive) throws {
        let now = Self.dateInitializer()
        let newExpiryDate = now.advanced(by: ttl)
        let maxExpiryDate = now.advanced(by: Self.timeToLiveActive)
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidExtendTime
        }
        expiryDate = newExpiryDate
    }
}
