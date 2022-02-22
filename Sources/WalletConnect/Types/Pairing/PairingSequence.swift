import Foundation
import WalletConnectKMS

struct PairingSequence: ExpirableSequence {
    
    let topic: String
    let relay: RelayProtocolOptions
    let selfParticipant: Participant
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
}
