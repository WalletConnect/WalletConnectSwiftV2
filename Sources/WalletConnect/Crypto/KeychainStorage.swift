import Foundation

//protocol Keychain {
//    subscript(key: String) -> Data? {get set}
//    func removeValue(forKey key: String)
//}

final class KeychainStorage {
    
    @discardableResult
    func add(_ data: Data, forKey key: String) -> Bool {
//        let id = key.data(using: .utf8)
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrIsInvisible: true,
//            kSecUseDataProtectionKeychain: true,
            kSecUseDataProtectionKeychain: false,
            kSecAttrService: "com.walletconnect",
            kSecAttrGeneric: key,
//            kSecAttrAccount: id,
            kSecValueData: data] as [String: Any]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            // error
            return true
        } else if status == errSecDuplicateItem {
            print("DUPLICATE ITEM")
            return false
        } else {
            print("GENERIC ERROR: \(status)")
            return false
        }
    }
    
    func read(forKey key: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrIsInvisible: true,
//            kSecUseDataProtectionKeychain: true,
            kSecUseDataProtectionKeychain: false,
            kSecAttrService: "com.walletconnect",
            kSecAttrGeneric: key,
//            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ] as [String: Any]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            guard let data = item as? Data else { fatalError() }
            return data
        } else if status == errSecItemNotFound {
//            fatalError() // throw not found
            return nil
        } else {
//            fatalError() // error generic
            return nil
        }
    }
    
    func delete(key: String) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrIsInvisible: true,
//            kSecUseDataProtectionKeychain: true,x1
            kSecUseDataProtectionKeychain: false,
            kSecAttrGeneric: key
        ] as [String: Any]
        
        let status = SecItemDelete(query as CFDictionary)
            
        if status == errSecSuccess {
            print("SUCCESS DELETE")
            return true
        } else {
            print("ERROR DELETE: \(status)")
            return false
        }
    }
    
    func deleteAll() {
        let query = [kSecClass: kSecClassGenericPassword]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            
        } else {
            print("error deleting all: \(status)")
        }
    }
    
    // - Private
    
    func addKey(data: Data) {
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
//            kSecAttrDescription: "api-key",
            kSecAttrIsInvisible: true,
            kSecUseDataProtectionKeychain: true,
            kSecValueData: data] as [String: Any]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            // error
            return
        }
    }
    
//    func getKey() {
//        let getQuery: [String: Any] = [
//            kSecClass as String: kSecClassGenericPassword,
//            kSecAttrApplicationTag as String: tag,
////            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
//            kSecMatchLimit: kSecMatchLimitOne,
//            kSecReturnRef as String: true
//        ]
//        var iten: CFTypeRef?
//        let status = SecItemCopyMatching(query as CFDictionary, &item)
//        if status == errSecSuccess {
//            let key = item as! SecKey
//        } else {
//            // throw
//        }
//    }
    
    func deleteKey(label: String) throws {
        let query = [kSecClass: kSecClassKey,
                     kSecUseDataProtectionKeychain: true,
                     kSecAttrApplicationLabel: label] as [String: Any]
        switch SecItemDelete(query as CFDictionary) {
        case errSecItemNotFound, errSecSuccess: break // Ignore these.
        case let status:
            break
//            throw KeyStoreError("Unexpected deletion error: \(status.message)")
        }
    }
    
    func deleteKey(account: String) throws {
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecUseDataProtectionKeychain: true, // required for x-platform
                     kSecAttrAccount: account] as [String: Any]
        switch SecItemDelete(query as CFDictionary) {
        case errSecItemNotFound, errSecSuccess: break // Okay to ignore
        case let status:
            throw KeyStoreError("Unexpected deletion error: \(status.message)")
        }
    }
    
    func deleteClass(_ secClass: AnyObject) -> Bool {
        let query = [kSecClass: secClass]
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
}

//kSecAttrLabel
//kSecAttrType
//kSecAttrService
//kSecAttrGeneric



struct KeyStoreError: Error, CustomStringConvertible {
    var message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var description: String {
        return message
    }
}

extension OSStatus {
    
    /// A human readable message for the status.
    var message: String {
        return (SecCopyErrorMessageString(self, nil) as String?) ?? String(self)
    }
}
