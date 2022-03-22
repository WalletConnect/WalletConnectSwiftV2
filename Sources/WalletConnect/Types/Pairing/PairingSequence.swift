import Foundation
import WalletConnectKMS

struct PairingSequence: ExpirableSequence {
    var publicKey: String?
    
    //todo - expirable sequence should not depend on pubKey but rather on map key
    let topic: String
    let relay: RelayProtocolOptions
    var state: PairingState?
    private (set) var isActive: Bool = false
    
    private (set) var expiryDate: Date

    static var timeToLiveProposed: Int {
        Time.hour
    }
    
    static var timeToLiveSettled: Int {
        Time.day * 30
    }
    
    mutating func activate() {
        isActive = true
        try! extend(Self.timeToLiveSettled)
    }
    
    mutating func extend(_ ttl: Int) throws {
        let newExpiryDate = Date(timeIntervalSinceNow: TimeInterval(ttl))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(PairingSequence.timeToLiveSettled))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidExtendTime
        }
        expiryDate = newExpiryDate
    }
    
    static func build(_ topic: String) -> PairingSequence {
        let relay = RelayProtocolOptions(protocol: "waku", data: nil)
        return PairingSequence(
            publicKey: nil,
            topic: topic,
            relay: relay,
            state: nil,
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(timeToLiveProposed)))
    }
    
    static func createFromURI(_ uri: WalletConnectURI) -> PairingSequence {
        return PairingSequence(
            topic: uri.topic,
            relay: uri.relay,
            expiryDate: Date(timeIntervalSinceNow: TimeInterval(timeToLiveSettled)))
    }
}
