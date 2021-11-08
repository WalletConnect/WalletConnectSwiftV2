import Foundation

protocol KeyValueStorage {
    func set(_ value: Any?, forKey defaultName: String)
    func object(forKey defaultName: String) -> Any?
    func data(forKey defaultName: String) -> Data?
    func removeObject(forKey defaultName: String)
    func dictionaryRepresentation() -> [String : Any]
}

extension UserDefaults: KeyValueStorage {}

final class RuntimeKeyValueStorage: KeyValueStorage {

    private var storage: [String : Any] = [:]

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }

    func data(forKey defaultName: String) -> Data? {
        return storage[defaultName] as? Data
    }

    func removeObject(forKey defaultName: String) {
        storage[defaultName] = nil
    }

    func dictionaryRepresentation() -> [String : Any] {
        return storage
    }
}
