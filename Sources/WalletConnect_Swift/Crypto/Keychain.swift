// 

import Foundation

protocol Keychain {
    subscript(key: String) -> Data? {get set}
    func removeValue(forKey key: String)
}

class DictionaryKeychain: Keychain {
    private let concurrentQueue = DispatchQueue(label: "wc_keychain_queue",
                                                attributes: .concurrent)
    private var keyValueStore = [String: Data]()
    subscript(key: String) -> Data? {
        get {
            concurrentQueue.sync {
                return keyValueStore[key]
            }
        }
        set(newValue) {
            self.concurrentQueue.async(flags: .barrier) { [weak self] in
                self?.keyValueStore[key] = newValue
            }
        }
    }
    
    func removeValue(forKey key: String) {
        concurrentQueue.async(flags: .barrier) {[weak self] in
            self?.keyValueStore.removeValue(forKey: key)
        }
    }
}
