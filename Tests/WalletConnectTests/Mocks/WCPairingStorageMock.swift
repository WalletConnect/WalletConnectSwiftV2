@testable import WalletConnect

final class WCPairingStorageMock: WCPairingStorage {
    
    var onPairingExpiration: ((WCPairing) -> Void)?
    
    private(set) var pairings: [String: WCPairing] = [:]
    
    func hasPairing(forTopic topic: String) -> Bool {
        pairings[topic] != nil
    }
    
    func setPairing(_ sequence: WCPairing) {
        pairings[sequence.topic] = sequence
    }
    
    func getPairing(forTopic topic: String) -> WCPairing? {
        pairings[topic]
    }
    
    func getAll() -> [WCPairing] {
        Array(pairings.values)
    }
    
    func delete(topic: String) {
        pairings[topic] = nil
    }
}
