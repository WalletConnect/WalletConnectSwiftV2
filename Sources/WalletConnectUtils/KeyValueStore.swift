
import Foundation

public final class KeyValueStore<T> where T: Codable {
    private let defaults: KeyValueStorage

    public init(defaults: KeyValueStorage) {
        self.defaults = defaults
    }

    public func set(_ item: T, forKey key: String) throws {
        let encoded = try JSONEncoder().encode(item)
        defaults.set(encoded, forKey: key)
    }

    public func get(key: String) throws -> T? {
        guard let data = defaults.object(forKey: key) as? Data else { return nil }
        let item = try JSONDecoder().decode(T.self, from: data)
        return item
    }

    public func getAll() -> [T] {
        return defaults.dictionaryRepresentation().compactMap {
            if let data = $0.value as? Data,
               let item = try? JSONDecoder().decode(T.self, from: data) {
                return item
            }
            return nil
        }
    }

    public func delete(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
