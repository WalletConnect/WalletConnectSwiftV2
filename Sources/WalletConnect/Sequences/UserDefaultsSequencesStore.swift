
import Foundation

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
        return defaults.dictionaryRepresentation().values.compactMap{
            if let data = $0 as? Data,
               let sequenceState = try? JSONDecoder().decode(SequenceState.self, from: data) {
                return sequenceState
            } else {return nil}
        }
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
