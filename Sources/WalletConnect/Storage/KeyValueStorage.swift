import Foundation

public protocol KeyValueStorage {
    func set(_ value: Any?, forKey defaultName: String)
    func object(forKey defaultName: String) -> Any?
    func data(forKey defaultName: String) -> Data?
    func removeObject(forKey defaultName: String)
    func dictionaryRepresentation() -> [String : Any]
}

extension UserDefaults: KeyValueStorage {}

// TODO: Move to test target
final class RuntimeKeyValueStorage: KeyValueStorage {

    private var storage: [String : Any] = [:]
    private let queue = DispatchQueue(label: "com.walletconnect.sdk.runtimestorage")

    func set(_ value: Any?, forKey defaultName: String) {
        queue.sync {
            storage[defaultName] = value
        }
    }

    func object(forKey defaultName: String) -> Any? {
        queue.sync {
            return storage[defaultName]
        }
    }

    func data(forKey defaultName: String) -> Data? {
        queue.sync {
            return storage[defaultName] as? Data
        }
    }

    func removeObject(forKey defaultName: String) {
        queue.sync {
            storage[defaultName] = nil
        }
    }

    func dictionaryRepresentation() -> [String : Any] {
        queue.sync {
            return storage
        }
    }
}
