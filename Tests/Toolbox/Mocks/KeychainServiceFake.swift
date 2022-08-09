import Foundation
@testable import WalletConnectKMS

final public class KeychainServiceFake: KeychainServiceProtocol {

    public var errorStatus: OSStatus?

    private var storage: [String: Data]

    public init() {
        self.storage = [:]
    }

    public func add(_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        if let forceError = errorStatus {
            return forceError
        }
        if let keyValue = getKeyAndData(from: attributes) {
            if storage[keyValue.key] == nil {
                storage[keyValue.key] = keyValue.data
                return errSecSuccess
            } else {
                return errSecDuplicateItem
            }
        }
        return errSecInternalError
    }

    public func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        if let forceError = errorStatus {
            return forceError
        }
        if let key = (query as NSDictionary).value(forKey: kSecAttrAccount as String) as? String {
            if let data = storage[key] {
                result?.pointee = data as CFTypeRef
                return errSecSuccess
            } else {
                return errSecItemNotFound
            }
        }
        return errSecInternalError
    }

    public func update(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus {
        if let forceError = errorStatus {
            return forceError
        }
        if let key = (query as NSDictionary).value(forKey: kSecAttrAccount as String) as? String,
           let newData = (attributesToUpdate as NSDictionary).value(forKey: kSecValueData as String) as? Data {
            if storage[key] == nil {
                return errSecItemNotFound
            } else {
                storage[key] = newData
                return errSecSuccess
            }
        }
        return errSecInternalError
    }

    public func delete(_ query: CFDictionary) -> OSStatus {
        if let forceError = errorStatus {
            return forceError
        }
        if let key = (query as NSDictionary).value(forKey: kSecAttrAccount as String) as? String {
            if storage[key] != nil {
                storage[key] = nil
                return errSecSuccess
            } else {
                return errSecItemNotFound
            }
        } else {
            if storage.isEmpty {
                return errSecItemNotFound
            } else {
                storage.removeAll()
                return errSecSuccess
            }
        }
    }

    private func getKeyAndData(from attributes: CFDictionary) -> (key: String, data: Data)? {
        let dict = (attributes as NSDictionary)
        if let data = dict[kSecValueData] as? Data,
           let key = dict[kSecAttrAccount] as? String {
            return (key, data)
        }
        return nil
    }
}
