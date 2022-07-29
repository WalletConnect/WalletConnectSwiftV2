import Foundation
import WalletConnectUtils

protocol WCSessionStorage: AnyObject {
    var onSessionExpiration: ((WCSession) -> Void)? { get set }
    @discardableResult
    func setSessionIfNewer(_ session: WCSession) -> Bool
    func setSession(_ session: WCSession)
    func hasSession(forTopic topic: String) -> Bool
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

    @discardableResult
    func setSessionIfNewer(_ session: WCSession) -> Bool {
        guard isNeedToReplace(session) else { return false }
        storage.setSequence(session)
        return true
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

// MARK: Privates

private extension SessionStorage {

    func isNeedToReplace(_ session: WCSession) -> Bool {
        guard let old = getSession(forTopic: session.topic) else { return true }
        return session.timestamp > old.timestamp
    }
}
