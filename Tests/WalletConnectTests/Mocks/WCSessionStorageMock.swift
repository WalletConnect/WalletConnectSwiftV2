@testable import WalletConnect
import Foundation

final class WCSessionStorageMock: WCSessionStorage {
    
    var onSessionExpiration: ((WCSession) -> Void)?
    
    private(set) var sessions: [String: WCSession] = [:]
    
    func hasSession(forTopic topic: String) -> Bool {
        sessions[topic] != nil
    }
    
    func setSession(_ sequence: WCSession) {
        sessions[sequence.topic] = sequence
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
}

