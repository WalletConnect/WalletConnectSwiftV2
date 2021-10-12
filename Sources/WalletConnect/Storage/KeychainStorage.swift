import Foundation
import CryptoKit

protocol GenericPasswordConvertible {
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes
    var rawRepresentation: Data { get }
}

extension Curve25519.KeyAgreement.PrivateKey: GenericPasswordConvertible {}

enum KeychainError: Error {
    case itemAlreadyExists(OSStatus)
    case itemNotFound(OSStatus)
    case failedToStoreItem(OSStatus)
    case failedToRead(OSStatus)
    case failedToUpdate(OSStatus)
    case failedToDelete(OSStatus)
}

final class KeychainStorage {
    
    let service = "com.walletconnect.sdk"
    
    private let secItem: KeychainServiceProtocol
    
    init(keychainService: KeychainServiceProtocol = KeychainServiceWrapper()) {
        self.secItem = keychainService
    }
    
    func add<T: GenericPasswordConvertible>(_ item: T, forKey key: String) throws {
        try add(data: item.rawRepresentation, forKey: key)
    }
    
    func add(data: Data, forKey key: String) throws {
        var query = buildBaseServiceQuery(for: key)
        query[kSecValueData] = data
        
        let status = secItem.add(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.itemAlreadyExists(status)
            }
            throw KeychainError.failedToStoreItem(status)
        }
    }
    
    func read<T: GenericPasswordConvertible>(key: String) throws -> T {
        guard let data = try readData(key: key) else {
            throw KeychainError.itemNotFound(errSecItemNotFound)
        }
        return try T(rawRepresentation: data)
    }
    
    func readData(key: String) throws -> Data? {
        var query = buildBaseServiceQuery(for: key)
        query[kSecReturnData] = true
        
        var item: CFTypeRef?
        let status = secItem.copyMatching(query as CFDictionary, &item)
        
        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.failedToRead(status)
        }
    }
    
    func update<T: GenericPasswordConvertible>(_ item: T, forKey key: String) throws {
        try update(data: item.rawRepresentation, forKey: key)
    }
    
    func update(data: Data, forKey key: String) throws {
        let query = buildBaseServiceQuery(for: key)
        let attributes = [kSecValueData: data]
        
        let status = secItem.update(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound(status)
            }
            throw KeychainError.failedToUpdate(status)
        }
    }
    
    func delete(key: String) throws {
        let query = buildBaseServiceQuery(for: key)
        
        let status = secItem.delete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.failedToDelete(status)
        }
    }
    
    func deleteAll() throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service
        ] as [String: Any]
        let status = secItem.delete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.failedToDelete(status)
        }
    }
    
    private func buildBaseServiceQuery(for key: String) -> [CFString: Any] {
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrIsInvisible: true,
            kSecUseDataProtectionKeychain: true,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
    }
}
