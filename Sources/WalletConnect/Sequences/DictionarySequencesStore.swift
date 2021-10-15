
import Foundation

class PairingDictionaryStore: DictionaryStore<PairingType.SequenceState>, PairingSequencesStore {
    func getSettled() -> [PairingType.Settled] {
        getAll().compactMap { sequence in
            switch sequence {
            case .settled(let settled):
                return settled
            case .pending(_):
                return nil
            }
        }
    }
}

class SessionDictionaryStore: DictionaryStore<SessionType.SequenceState>, SessionSequencesStore {
    func getSettled() -> [SessionType.Settled] {
        getAll().compactMap { sequence in
            switch sequence {
            case .settled(let settled):
                return settled
            case .pending(_):
                return nil
            }
        }
    }
}

class DictionaryStore<T> {
    private let serialQueue = DispatchQueue(label: "sequence queue: \(UUID().uuidString)")
    private var sequences = [String: T]()
    private let logger: BaseLogger

    init(logger: BaseLogger) {
        self.logger = logger
    }
    
    func create(topic: String, sequenceState: T) {
        serialQueue.sync {
            sequences[topic] = sequenceState
        }
    }
    
    func getAll() -> [T] {
        serialQueue.sync {
            sequences.map{$0.value}
        }
    }
    
    func get(topic: String) -> T? {
        serialQueue.sync {
            sequences[topic]
        }
    }
    
    func update(topic: String, newTopic: String?, sequenceState: T) {
        serialQueue.async { [weak self] in
            if let newTopic = newTopic {
                self?.sequences.removeValue(forKey: topic)
                self?.sequences[newTopic] = sequenceState
            } else {
                self?.sequences[topic] = sequenceState
            }
        }
    }
    
    func delete(topic: String) {
        logger.debug("Deleted sequence for topic: \(topic)")
        serialQueue.async { [weak self] in
            self?.sequences.removeValue(forKey: topic)
        }
    }
}
