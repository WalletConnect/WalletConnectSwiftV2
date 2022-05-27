protocol WCSessionStorage: AnyObject {
    var onSessionExpiration: ((WCSession) -> Void)? { get set }
    func hasSession(forTopic topic: String) -> Bool
    func setSession(_ session: WCSession)
    func getSession(forTopic topic: String) -> WCSession?
    func getAll() -> [WCSession]
    func delete(topic: String)
    func deleteAll()
}

final class SessionStorage: WCSessionStorage {
    
    var onSessionExpiration: ((WCSession) -> Void)?
    
    private let storage: SequenceStore<WCSession>
    
    init(storage: SequenceStore<WCSession>) {
        self.storage = storage
        storage.onSequenceExpiration = { [unowned self] session in
            onSessionExpiration?(session)
        }
    }
    
    func hasSession(forTopic topic: String) -> Bool {
        storage.hasSequence(forTopic: topic)
    }
    
    func setSession(_ session: WCSession) {
        storage.setSequence(session)
    }
    
    func getSession(forTopic topic: String) -> WCSession? {
        return try? storage.getSequence(forTopic: topic)
    }
    
    func getAll() -> [WCSession] {
        storage.getAll()
    }
    
    func delete(topic: String) {
        storage.delete(topic: topic)
    }
    
    func deleteAll() {
        storage.deleteAll()
    }
}
