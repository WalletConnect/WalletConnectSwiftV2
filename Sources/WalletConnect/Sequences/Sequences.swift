
import Foundation

protocol SequencesStore {
    func create(topic: String, sequenceState: SequenceState)
    func getAll() -> [SequenceState]
    func getSettled() -> [SequenceSettled]
    func get(topic: String) -> SequenceState?
    func update(topic: String, newTopic: String?, sequenceState: SequenceState)
    func delete(topic: String)
}

class UserDefaultsSequencesStore: SequencesStore {
    // The UserDefaults class is thread-safe.
    let emo: String
    init() {
        self.emo = ["😌","🥰","😂","🤩","🥳"].randomElement()!
    }
    private var defaults = UserDefaults.standard
    
    func create(topic: String, sequenceState: SequenceState) {
        print("\(emo)will save for key: \(topic)")

        if let encoded = try? JSONEncoder().encode(sequenceState) {
            defaults.set(encoded, forKey: topic)
            defaults.dictionaryRepresentation()
        }
    }
    
    func getAll() -> [SequenceState] {
        return defaults.dictionaryRepresentation().values.compactMap{$0 as? SequenceState}
    }
    
    func getSettled() -> [SequenceSettled] {
        getAll().compactMap { sequence in
            switch sequence {
            case .settled(let settled):
                return settled
            case .pending(_):
                return nil
            }
        }
    }
    
    func get(topic: String) -> SequenceState? {
        print("\(emo)will read for key \(topic)")

        if let data = defaults.object(forKey: topic) as? Data,
           let sequenceState = try? JSONDecoder().decode(SequenceState.self, from: data) {
            return sequenceState
        }
        print("\(emo)could not find  value for key \(topic)")

        return nil
    }
    
    func update(topic: String, newTopic: String? = nil, sequenceState: SequenceState) {
        if let newTopic = newTopic {
            defaults.removeObject(forKey: topic)
            create(topic: newTopic, sequenceState: sequenceState)
        } else {
            create(topic: topic, sequenceState: sequenceState)
        }
    }
    
    func delete(topic: String) {
        Logger.debug("Will delete sequence for topic: \(topic)")
        defaults.removeObject(forKey: topic)
    }
}


class DictionarySequencesStore: SequencesStore {

    let serialQueue = DispatchQueue(label: "sequence queue: \(UUID().uuidString)")
    var sequences = [String: SequenceState]()
    
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
