
import Foundation

class DictionarySequencesStore: SequencesStore {
    private let serialQueue = DispatchQueue(label: "sequence queue: \(UUID().uuidString)")
    private var sequences = [String: SequenceState]()
    
    func create(topic: String, sequenceState: SequenceState) {
        serialQueue.sync {
            sequences[topic] = sequenceState
        }
    }
    
    func getAll() -> [SequenceState] {
        serialQueue.sync {
            sequences.map{$0.value}
        }
    }
    
    func getSettled() -> [SequenceSettled] {
        getAll().compactMap { sequenceState in
            switch sequenceState {
            case .settled(let settled):
                return settled
            case .pending(_):
                return nil
            }
        }
    }
        
    func get(topic: String) -> SequenceState? {
        serialQueue.sync {
            sequences[topic]
        }
    }
    
    func update(topic: String, newTopic: String?, sequenceState: SequenceState) {
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
