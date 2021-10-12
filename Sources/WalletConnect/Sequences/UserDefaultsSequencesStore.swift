
import Foundation

class PairingUserDefaultsStore: UserDefaultsStore<PairingType.SequenceState>, PairingSequencesStore {
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

class SessionUserDefaultsStore: UserDefaultsStore<SessionType.SequenceState>, SessionSequencesStore {
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

class UserDefaultsStore<T: Codable> {
    private var defaults = UserDefaults.standard
    
    func create(topic: String, sequenceState: T) {
        if let encoded = try? JSONEncoder().encode(sequenceState) {
            defaults.set(encoded, forKey: topic)
            defaults.dictionaryRepresentation()
        }
    }
    
    func getAll() -> [T] {
        return defaults.dictionaryRepresentation().values.compactMap{
            if let data = $0 as? Data,
               let sequenceState = try? JSONDecoder().decode(T.self, from: data) {
                return sequenceState
            } else {return nil}
        }
    }
    
    func get(topic: String) -> T? {
        if let data = defaults.object(forKey: topic) as? Data,
           let sequenceState = try? JSONDecoder().decode(T.self, from: data) {
            return sequenceState
        }
        return nil
    }
    
    func update(topic: String, newTopic: String? = nil, sequenceState: T) {
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
