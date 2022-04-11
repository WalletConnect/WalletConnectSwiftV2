protocol WCPairingStorage: AnyObject {
    var onPairingExpiration: ((WCPairing) -> Void)? { get set }
    func hasPairing(forTopic topic: String) -> Bool
    func setPairing(_ pairing: WCPairing)
    func getPairing(forTopic topic: String) -> WCPairing?
    func getAll() -> [WCPairing]
    func delete(topic: String)
}

final class PairingStorage: WCPairingStorage {
    
    var onPairingExpiration: ((WCPairing) -> Void)? {
        get { storage.onSequenceExpiration }
        set { storage.onSequenceExpiration = newValue }
    }
    
    private let storage: SequenceStore<WCPairing>
    
    init(storage: SequenceStore<WCPairing>) {
        self.storage = storage
    }
    
    func hasPairing(forTopic topic: String) -> Bool {
        storage.hasSequence(forTopic: topic)
    }
    
    func setPairing(_ pairing: WCPairing) {
        storage.setSequence(pairing)
    }
    
    func getPairing(forTopic topic: String) -> WCPairing? {
        try? storage.getSequence(forTopic: topic)
    }
    
    func getAll() -> [WCPairing] {
        storage.getAll()
    }
    
    func delete(topic: String) {
        storage.delete(topic: topic)
    }
}
