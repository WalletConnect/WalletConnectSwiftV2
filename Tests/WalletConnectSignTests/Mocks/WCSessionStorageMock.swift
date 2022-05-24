@testable import WalletConnectAuth
import Foundation

final class WCSessionStorageMock: WCSessionStorage {
    var onSessionExpiration: ((WCSession) -> Void)?
    
    private(set) var sessions: [String: WCSession] = [:]
    
    func hasSession(forTopic topic: String) -> Bool {
        sessions[topic] != nil
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
    
    func getAcknowledgedSessions() -> [WCSession] {
        getAll().compactMap {
            guard $0.acknowledged else { return nil }
            return $0
        }
    }
}

