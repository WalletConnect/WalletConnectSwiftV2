@testable import WalletConnect

final class WCPairingStorageMock: WCPairingStorage {
    
    var onSequenceExpiration: ((WCPairing) -> Void)?
    
    private(set) var pairings: [String: WCPairing] = [:]
    
    func hasSequence(forTopic topic: String) -> Bool {
        pairings[topic] != nil
    }
    
    func setSequence(_ sequence: WCPairing) {
        pairings[sequence.topic] = sequence
    }
    
    func getSequence(forTopic topic: String) -> WCPairing? {
        pairings[topic]
    }
    
    func getAll() -> [WCPairing] {
        Array(pairings.values)
    }
    
    func delete(topic: String) {
        pairings[topic] = nil
    }
}
