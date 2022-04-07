import Foundation
import WalletConnectKMS

struct PairingSequence: ExpirableSequence {
    
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
    
    struct Participants: Codable, Equatable {
        var `self`: AppMetadata?
        var peer: AppMetadata?
    }
    
    let topic: String
    let relay: RelayProtocolOptions
    var participants: Participants
    
    private (set) var isActive: Bool = false
    private (set) var expiryDate: Date
    
    mutating func activate() {
        isActive = true
    }
    
    mutating func extend(_ ttl: Int = Int(PairingSequence.timeToLiveActive)) throws {
//        let now = Date()
        let newExpiryDate = Date(timeIntervalSinceNow: TimeInterval(ttl))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(PairingSequence.timeToLiveActive))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidExtendTime
        }
        expiryDate = newExpiryDate
    }
    
    static func build(_ topic: String, selfMetadata: AppMetadata) -> PairingSequence {
        let relay = RelayProtocolOptions(protocol: "waku", data: nil)
        return PairingSequence(
            topic: topic,
            relay: relay,
            participants: Participants(
                self: selfMetadata,
                peer: nil),
            expiryDate: dateInitializer().advanced(by: timeToLiveInactive))
    }
    
    static func createFromURI(_ uri: WalletConnectURI) -> PairingSequence {
        return PairingSequence(
            topic: uri.topic,
            relay: uri.relay,
            participants: Participants(
                self: nil,
                peer: nil),
            expiryDate: dateInitializer().advanced(by: timeToLiveInactive))
    }
}
