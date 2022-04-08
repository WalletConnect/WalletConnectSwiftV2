protocol WCSessionStorage: AnyObject {
    var onSequenceExpiration: ((WCSession) -> Void)? { get set }
    func hasSequence(forTopic topic: String) -> Bool
    func setSequence(_ sequence: WCSession)
    func getSequence(forTopic topic: String) -> WCSession?
    func getAll() -> [WCSession]
    func delete(topic: String)
}

final class SessionStorage: WCSessionStorage {
    
    var onSequenceExpiration: ((WCSession) -> Void)?
    
    private let storage: SequenceStore<WCSession>
    
    init(storage: SequenceStore<WCSession>) {
        self.storage = storage
        storage.onSequenceExpiration = { [unowned self] session in
            onSequenceExpiration?(session)
        }
    }
    
    func hasSequence(forTopic topic: String) -> Bool {
        storage.hasSequence(forTopic: topic)
    }
    
    func setSequence(_ sequence: WCSession) {
        storage.setSequence(sequence)
    }
    
    func getSequence(forTopic topic: String) -> WCSession? {
        return try? storage.getSequence(forTopic: topic)
    }
    
    func getAll() -> [WCSession] {
        storage.getAll()
    }
    
    func delete(topic: String) {
        storage.delete(topic: topic)
    }
}
