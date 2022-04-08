protocol WCPairingStorage: AnyObject {
    var onSequenceExpiration: ((WCPairing) -> Void)? { get set }
    func hasSequence(forTopic topic: String) -> Bool
    func setSequence(_ sequence: WCPairing)
    func getSequence(forTopic topic: String) -> WCPairing?
    func getAll() -> [WCPairing]
    func delete(topic: String)
}

final class PairingStorage: WCPairingStorage {
    
    var onSequenceExpiration: ((WCPairing) -> Void)? {
        get { storage.onSequenceExpiration }
        set { storage.onSequenceExpiration = newValue }
    }
    
    private let storage: SequenceStore<WCPairing>
    
    init(storage: SequenceStore<WCPairing>) {
        self.storage = storage
    }
    
    func hasSequence(forTopic topic: String) -> Bool {
        storage.hasSequence(forTopic: topic)
    }
    
    func setSequence(_ sequence: WCPairing) {
        storage.setSequence(sequence)
    }
    
    func getSequence(forTopic topic: String) -> WCPairing? {
        try? storage.getSequence(forTopic: topic)
    }
    
    func getAll() -> [WCPairing] {
        storage.getAll()
    }
    
    func delete(topic: String) {
        storage.delete(topic: topic)
    }
}
