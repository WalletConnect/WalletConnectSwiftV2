
import Foundation

final class KeyValueStore<T> where T: Codable {
    private let defaults: KeyValueStorage

    init(defaults: KeyValueStorage) {
        self.defaults = defaults
    }

    func set(_ item: T, forKey key: String) throws {
        let encoded = try JSONEncoder().encode(item)
        defaults.set(encoded, forKey: key)
    }

    func get(key: String) throws -> T? {
        guard let data = defaults.object(forKey: key) as? Data else { return nil }
        let item = try JSONDecoder().decode(T.self, from: data)
        return item
    }

    func getAll() -> [T] {
        return defaults.dictionaryRepresentation().compactMap {
            if let data = $0.value as? Data,
               let item = try? JSONDecoder().decode(T.self, from: data) {
                return item
            }
            return nil
        }
    }

    func delete(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
