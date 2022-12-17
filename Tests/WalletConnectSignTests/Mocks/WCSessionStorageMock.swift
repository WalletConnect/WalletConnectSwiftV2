@testable import WalletConnectSign
import Foundation

final class WCSessionStorageMock: WCSessionStorage {

    var onSessionsUpdate: (() -> Void)?
    var onSessionExpiration: ((WCSession) -> Void)?

    private(set) var sessions: [String: WCSession] = [:]

    func hasSession(forTopic topic: String) -> Bool {
        sessions[topic] != nil
    }

    @discardableResult
    func setSessionIfNewer(_ session: WCSession) -> Bool {
        guard isNeedToReplace(session) else { return false }
        sessions[session.topic] = session
        return true
    }

    func setSession(_ session: WCSession) {
        sessions[session.topic] = session
    }

    func getSession(forTopic topic: String) -> WCSession? {
        return sessions[topic]
    }

    func getAll() -> [WCSession] {
        Array(sessions.values)
    }

    func delete(topic: String) {
        sessions[topic] = nil
    }

    func deleteAll() {
        sessions = [:]
    }
}

// MARK: Privates

private extension WCSessionStorageMock {

    func isNeedToReplace(_ session: WCSession) -> Bool {
        guard let old = getSession(forTopic: session.topic) else { return true }
        return session.timestamp > old.timestamp
    }
}
