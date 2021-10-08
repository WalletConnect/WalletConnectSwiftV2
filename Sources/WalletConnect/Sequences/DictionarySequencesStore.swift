
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
        serialQueue.sync {
            if let newTopic = newTopic {
                sequences.removeValue(forKey: topic)
                sequences[newTopic] = sequenceState
            } else {
                sequences[topic] = sequenceState
            }
        }
    }
    
    func delete(topic: String) {
        Logger.debug("Will delete sequence for topic: \(topic)")
        serialQueue.sync {
            sequences.removeValue(forKey: topic)
        }
    }
}
