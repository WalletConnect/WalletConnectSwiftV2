import Foundation

public protocol KeychainStorageProtocol {
    func add<T: GenericPasswordConvertible>(_ item: T, forKey key: String) throws
    func read<T: GenericPasswordConvertible>(key: String) throws -> T
    func delete(key: String) throws
    func deleteAll() throws
}

public final class KeychainStorage: KeychainStorageProtocol {

    private let service: String

    private let secItem: KeychainServiceProtocol

    public init(keychainService: KeychainServiceProtocol = KeychainServiceWrapper(), serviceIdentifier: String) {
        self.secItem = keychainService
        service = serviceIdentifier
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
            return tryMigrateAttrAccessibleOnRead(key: key) // TODO: Replace with nil once migration period ends
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
        
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            try tryMigrateAttrAccessibleOnUpdate(data: data, key: key) // TODO: Remove once migration period ends
        default:
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
            kSecAttrService: service
        ] as [String: Any]
        let status = secItem.delete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError(status)
        }
    }

    private func buildBaseServiceQuery(for key: String) -> [CFString: Any] {
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrIsInvisible: true,
            kSecUseDataProtectionKeychain: true,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
    }

    private func tryMigrateAttrAccessibleOnRead(key: String) -> Data? {
        var updateQuery = buildBaseServiceQuery(for: key)
        updateQuery[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let attributes = [kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let status = secItem.update(updateQuery as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            return nil
        }

        var readQuery = buildBaseServiceQuery(for: key)
        readQuery[kSecReturnData] = true

        var item: CFTypeRef?
        _ = secItem.copyMatching(readQuery as CFDictionary, &item)

        return item as? Data
    }

    private func tryMigrateAttrAccessibleOnUpdate(data: Data, key: String) throws {
        var updateAccessQuery = buildBaseServiceQuery(for: key)
        updateAccessQuery[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let accessAttributes = [kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let accessStatus = secItem.update(updateAccessQuery as CFDictionary, accessAttributes as CFDictionary)

        guard accessStatus == errSecSuccess else {
            throw KeychainError.itemNotFound
        }

        let updateQuery = buildBaseServiceQuery(for: key)
        let updateAttributes = [kSecValueData: data]

        let updateStatus = secItem.update(updateQuery as CFDictionary, updateAttributes as CFDictionary)

        guard updateStatus == errSecSuccess else {
            throw KeychainError.itemNotFound
        }
    }
}
