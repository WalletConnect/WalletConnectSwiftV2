import Foundation
import WalletConnectKMS

struct PairingSequence: ExpirableSequence {
    struct Participants: Codable, Equatable {
        let `self`: Participant
        let peer: Participant
    }    
    let topic: String
    let relay: RelayProtocolOptions
    var state: PairingState?
//    var participants: Participants
    private (set) var isActive: Bool = false
    
    private (set) var expiryDate: Date

    static var timeToLiveInactive: Int {
        5 * Time.minute
    }
    
    static var timeToLiveActive: Int {
        Time.day * 30
    }
    
    mutating func activate() {
        isActive = true
    }
    
    mutating func extend(_ ttl: Int = PairingSequence.timeToLiveActive) throws {
        let newExpiryDate = Date(timeIntervalSinceNow: TimeInterval(ttl))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(PairingSequence.timeToLiveActive))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidExtendTime
        }
        expiryDate = newExpiryDate
    }
    
    static func build(_ topic: String) -> PairingSequence {
        let relay = RelayProtocolOptions(protocol: "waku", data: nil)
        return PairingSequence(
            topic: topic,
            relay: relay,
            state: nil,
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(timeToLiveInactive)))
    }
    
    static func createFromURI(_ uri: WalletConnectURI) -> PairingSequence {
        return PairingSequence(
            topic: uri.topic,
            relay: uri.relay,
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(timeToLiveActive)))
    }
}
