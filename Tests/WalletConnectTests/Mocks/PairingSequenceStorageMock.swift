@testable import WalletConnect

final class PairingSequenceStorageMock: PairingSequenceStorage {
    
    var onSequenceExpiration: ((String, String) -> Void)?
    
    private(set) var pairings: [String: PairingSequence] = [:]
    
    func hasSequence(forTopic topic: String) -> Bool {
        pairings[topic] != nil
    }
    
    func setSequence(_ sequence: PairingSequence) {
        pairings[sequence.topic] = sequence
    }
    
    func getSequence(forTopic topic: String) throws -> PairingSequence? {
        pairings[topic]
    }
    
    func getAll() -> [PairingSequence] {
        Array(pairings.values)
    }
    
    func delete(topic: String) {
        pairings[topic] = nil
    }
}

extension PairingSequenceStorageMock {
    
    func hasPendingRespondedPairing(on topic: String) -> Bool {
        pairings[topic]?.pending?.status == .responded
    }
    
    func hasPreSettledPairing(on topic: String) -> Bool {
        pairings[topic]?.settled?.status == .preSettled
    }
}
