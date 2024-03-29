import Foundation
import Combine

public final class CodableStore<T> where T: Codable {
    private let defaults: KeyValueStorage
    private let prefix: String
    private let migrationQueue = DispatchQueue(label: "com.walletconnect.CodableStore.migration")

    public var storeUpdatePublisher: AnyPublisher<Void, Never> {
        storeUpdatePublisherSubject.eraseToAnyPublisher()
    }
    private let storeUpdatePublisherSubject = PassthroughSubject<Void, Never>()

    public init(defaults: KeyValueStorage, identifier: String) {
        self.defaults = defaults
        self.prefix = identifier
        migrateIfNeeded()
    }

    public func set(_ item: T, forKey key: String) {
        // This force-unwrap is safe because T are JSON Encodable
        let encoded = try! JSONEncoder().encode(item)
        defaults.set(encoded, forKey: getContextPrefixedKey(for: key))
        storeUpdatePublisherSubject.send()
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
        storeUpdatePublisherSubject.send()
    }

    public func delete(forKeys keys: [String]) {
        keys.forEach { key in
            defaults.removeObject(forKey: getContextPrefixedKey(for: key))
        }
        storeUpdatePublisherSubject.send()
    }

    public func deleteAll() {
        dictionaryForIdentifier()
            .forEach { defaults.removeObject(forKey: $0.key) }
        storeUpdatePublisherSubject.send()
    }

    private func getContextPrefixedKey(for key: String) -> String {
        return "\(prefix).\(key)"
    }

    private func dictionaryForIdentifier() -> [String: Any] {
        return defaults.dictionaryRepresentation()
            .filter { $0.key.hasPrefix("\(prefix).") }
    }


    private func migrateIfNeeded() {
        migrationQueue.sync {
            let migrationKey = "hasMigratedToGroup_\(prefix)"
            guard let groupDefaults = defaults as? UserDefaults,
                  groupDefaults != UserDefaults.standard,
                  !groupDefaults.bool(forKey: migrationKey) else {
                return
            }

            let oldStore = CodableStore<T>(defaults: UserDefaults.standard, identifier: prefix)
            let oldItemsDictionary = oldStore.dictionaryForIdentifier()

            for (key, value) in oldItemsDictionary {
                if let data = value as? Data {
                    groupDefaults.set(data, forKey: key)
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }

            groupDefaults.set(true, forKey: migrationKey)
            storeUpdatePublisherSubject.send()
        }
    }

}
