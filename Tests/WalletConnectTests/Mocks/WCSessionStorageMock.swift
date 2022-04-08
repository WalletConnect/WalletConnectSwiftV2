@testable import WalletConnect
import Foundation

final class WCSessionStorageMock: WCSessionStorage {
    
    var onSequenceExpiration: ((WCSession) -> Void)?
    
    private(set) var sessions: [String: WCSession] = [:]
    
    func hasSequence(forTopic topic: String) -> Bool {
        sessions[topic] != nil
    }
    
    func setSequence(_ sequence: WCSession) {
        sessions[sequence.topic] = sequence
    }
    
    func getSequence(forTopic topic: String) -> WCSession? {
        return sessions[topic]
    }
    
    func getAll() -> [WCSession] {
        Array(sessions.values)
    }
    
    func delete(topic: String) {
        sessions[topic] = nil
    }
}

