import Foundation

// TODO: Add methods for crypto key parameters
final class SecureStorage {
    
    private let keychain: KeychainStorageProtocol
    private let queue: DispatchQueue
    
    private let api = "api-key"
    
    init(keychain: KeychainStorageProtocol,
         dispatchQueue: DispatchQueue = DispatchQueue(label: "com.walletconnect.keychain.queue", qos: .default)) {
        self.keychain = keychain
        self.queue = dispatchQueue
    }
    
    func set<T>(_ value: T, forKey key: String) where T : GenericPasswordConvertible {
        queue.async { [weak self] in
            try? self?.keychain.add(value, forKey: key)
        }
    }
    
    func get<T>(key: String) -> T? where T : GenericPasswordConvertible {
        queue.sync {
            try? keychain.read(key: key)
        }
    }
    
    func removeValue(forKey key: String) {
        queue.async { [weak self] in
            try? self?.keychain.delete(key: key)
        }
    }
}
