@testable import WalletConnect

final class SessionSequenceStorageMock: SessionSequenceStorage {
    
    var onSequenceExpiration: ((String, String) -> Void)?
    
    private(set) var sessions: [String: SessionSequence] = [:]
    
    func hasSequence(forTopic topic: String) -> Bool {
        sessions[topic] != nil
    }
    
    func setSequence(_ sequence: SessionSequence) {
        sessions[sequence.topic] = sequence
    }
    
    func getSequence(forTopic topic: String) throws -> SessionSequence? {
        sessions[topic]
    }
    
    func getAll() -> [SessionSequence] {
        Array(sessions.values)
    }
    
    func delete(topic: String) {
        sessions[topic] = nil
    }
}
