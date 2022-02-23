import Foundation
import WalletConnectKMS

struct PairingSequence: ExpirableSequence {
    var publicKey: String
    
    //todo - expirable sequence should not depend on pubKey but rather on map key
    let topic: String
    let relay: RelayProtocolOptions
    //TODO - is state needed when we have two participants with metadata
    let selfParticipant: Participant
    let peerParticipant: Participant
    var state: PairingState?
    
    private (set) var expiryDate: Date

    static var timeToLiveProposed: Int {
        Time.hour
    }
    
    static var timeToLivePending: Int {
        Time.day
    }
    
    static var timeToLiveSettled: Int {
        Time.day * 30
    }
    
    mutating func extend(_ ttl: Int) throws {
        let newExpiryDate = Date(timeIntervalSinceNow: TimeInterval(ttl))
        let maxExpiryDate = Date(timeIntervalSinceNow: TimeInterval(PairingSequence.timeToLiveSettled))
        guard newExpiryDate > expiryDate && newExpiryDate <= maxExpiryDate else {
            throw WalletConnectError.invalidExtendTime
        }
        expiryDate = newExpiryDate
    }
    
    static func build() {
        
    }
}
