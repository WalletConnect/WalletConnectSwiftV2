
import Foundation

public final class GroupKeychainStorage: KeychainStorageProtocol {

    private let accessGroup: String

    private let secItem: KeychainServiceProtocol

    public init(keychainService: KeychainServiceProtocol = KeychainServiceWrapper(), serviceIdentifier: String) {
        self.secItem = keychainService
        accessGroup = serviceIdentifier
    }

    public func add<T>(_ item: T, forKey key: String) throws where T: GenericPasswordConvertible {
        try add(data: item.rawRepresentation, forKey: key)
    }

    public func add(data: Data, forKey key: String) throws {
        var query = buildBaseServiceQuery(for: key)
        query[kSecValueData] = data

        let status = secItem.add(query as CFDictionary, nil)

        guard status != errSecDuplicateItem else {
            return try update(data: data, forKey: key)
        }

        guard status == errSecSuccess else {
            throw KeychainError(status)
        }
    }

    public func read<T>(key: String) throws -> T where T: GenericPasswordConvertible {
        guard let data = try readData(key: key) else {
            throw KeychainError(errSecItemNotFound)
        }
        return try T(rawRepresentation: data)
    }

    public func readData(key: String) throws -> Data? {
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
            throw KeychainError(status)
        }
    }

    public func update<T>(_ item: T, forKey key: String) throws where T: GenericPasswordConvertible {
        try update(data: item.rawRepresentation, forKey: key)
    }

    public func update(data: Data, forKey key: String) throws {
        let query = buildBaseServiceQuery(for: key)
        let attributes = [kSecValueData: data]

        let status = secItem.update(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            throw KeychainError(status)
        }
    }

    public func delete(key: String) throws {
        let query = buildBaseServiceQuery(for: key)

        let status = secItem.delete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status)
        }
    }

    public func deleteAll() throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: accessGroup
        ] as [String: Any]
        let status = secItem.delete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError(status)
        }
    }

    private func buildBaseServiceQuery(for key: String) -> [CFString: Any] {
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrIsInvisible: true,
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccessGroup: accessGroup,
            kSecAttrAccount: key
        ]
    }
}
