@testable import WalletConnect

final class PairingSequenceStorageMock: PairingSequenceStorage {
    
    var onSequenceExpiration: ((String, String?) -> Void)?
    
    private(set) var pairings: [String: PairingSequence] = [:]
    
    func hasSequence(forTopic topic: String) -> Bool {
        pairings[topic] != nil
    }
    
    func setSequence(_ sequence: PairingSequence) {
        pairings[sequence.topic] = sequence
    }
    
    func getSequence(forTopic topic: String) -> PairingSequence? {
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
//    TODO - distinguish by expiration time
//    func hasPendingProposedPairing(on topic: String) -> Bool {
//        guard case .proposed = pairings[topic]?.pending?.status else { return false }
//        return true
//    }
//
//    func hasAcknowledgedPairing(on topic: String) -> Bool {
//        pairings[topic]?.settled?.status == .acknowledged
//    }
}
