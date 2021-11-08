import Foundation

protocol Expirable {
    var expiryDate: Date { get }
}

final class SequenceStore<T> where T: Codable, T: Expirable {

    private let defaults: KeyValueStorage
    private let dateInitializer: () -> Date

    init(defaults: KeyValueStorage, dateInitializer: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.dateInitializer = dateInitializer
    }

    func set(_ item: T, forKey key: String) throws {
        let encoded = try JSONEncoder().encode(item)
        defaults.set(encoded, forKey: key)
    }

    func get(key: String) throws -> T? {
        guard let data = defaults.object(forKey: key) as? Data else { return nil }
        let item = try JSONDecoder().decode(T.self, from: data)

        let now = dateInitializer()
        if now >= item.expiryDate {
            defaults.removeObject(forKey: key)
            // call expire event
            return nil
        }
        return item
    }

    func getAll() -> [T] {
        return defaults.dictionaryRepresentation().compactMap {
            if let data = $0.value as? Data, let item = try? JSONDecoder().decode(T.self, from: data) {

                let now = dateInitializer()
                if now >= item.expiryDate {
                    defaults.removeObject(forKey: $0.key)
                    // call expire event
                    return nil
                }
                return item
            }
            return nil
        }
    }

    func update(topic: String, newTopic: String? = nil, sequenceState: T) throws {
        if let newTopic = newTopic {
            defaults.removeObject(forKey: topic)
            try set(sequenceState, forKey: newTopic)
        } else {
            try set(sequenceState, forKey: topic)
        }
    }

    func delete(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
