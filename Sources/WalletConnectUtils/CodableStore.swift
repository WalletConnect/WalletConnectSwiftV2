import Foundation

public final class CodableStore<T> where T: Codable {
    private let defaults: KeyValueStorage
    private let prefix: String

    public init(defaults: KeyValueStorage, identifier: String) {
        self.defaults = defaults
        self.prefix = identifier
    }

    public func set(_ item: T, forKey key: String) {
        // This force-unwrap is safe because T are JSON Encodable
        let encoded = try! JSONEncoder().encode(item)
        defaults.set(encoded, forKey: getContextPrefixedKey(for: key))
    }

    public func get(key: String) throws -> T? {
        guard let data = defaults.object(forKey: getContextPrefixedKey(for: key)) as? Data else { return nil }
        let item = try JSONDecoder().decode(T.self, from: data)
        return item
    }

    public func getAll() -> [T] {
        return dictionaryForIdentifier().compactMap {
            if let data = $0.value as? Data,
               let item = try? JSONDecoder().decode(T.self, from: data) {
                return item
            }
            return nil
        }
    }

    public func delete(forKey key: String) {
        defaults.removeObject(forKey: getContextPrefixedKey(for: key))
    }

    public func deleteAll() {
        dictionaryForIdentifier()
            .forEach { defaults.removeObject(forKey: $0.key) }
    }

    private func getContextPrefixedKey(for key: String) -> String {
        return "\(prefix).\(key)"
    }

    private func dictionaryForIdentifier() -> [String: Any] {
        return defaults.dictionaryRepresentation()
            .filter { $0.key.hasPrefix("\(prefix).") }
    }
}
