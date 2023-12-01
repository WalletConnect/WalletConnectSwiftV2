import Foundation

public protocol KeychainStorageProtocol {
    func add<T: GenericPasswordConvertible>(_ item: T, forKey key: String) throws
    func read<T: GenericPasswordConvertible>(key: String) throws -> T
    func delete(key: String) throws
    func deleteAll() throws
}

public final class KeychainStorage: KeychainStorageProtocol {

    private let service: String
    private let accessGroup: String
    private let synchronizationQueue = DispatchQueue(label: "com.yourapp.KeychainStorage")

    private let secItem: KeychainServiceProtocol

    public init(
        keychainService: KeychainServiceProtocol = KeychainServiceWrapper(),
        serviceIdentifier: String,
        accessGroup: String
    ) {
        self.secItem = keychainService
        self.accessGroup = accessGroup
        self.service = serviceIdentifier
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
            return try synchronizationQueue.sync {
                // Try to update the accessibility attribute first - migration V1
                tryUpdateAccessibilityAttribute(key: key)
                // Then attempt to migrate to the new access group and return if item exists - migration V2
                if let updatedData = try tryToMigrateKeyToNewAccessGroupOnRead(key: key) {
                    return updatedData
                } else {
                    return nil
                }
            }
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
            // Try to update the accessibility attribute - migration V1
            tryUpdateAccessibilityAttribute(key: key)
            // Then attempt to migrate to the new access group - migration V2
            try tryToMigrateKeyToNewAccessGroupOnUpdate(data: data, key: key)
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
            kSecAttrAccessGroup: accessGroup,
            kSecAttrAccount: key
        ]
    }


    private func tryUpdateAccessibilityAttribute(key: String) {
        var updateQuery = buildBaseServiceQuery(for: key)
        updateQuery.removeValue(forKey: kSecAttrAccessGroup)
        updateQuery[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let attributes = [kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let _ = secItem.update(updateQuery as CFDictionary, attributes as CFDictionary)
    }

    private func tryToMigrateKeyToNewAccessGroupOnRead(key: String) throws -> Data? {
        tryToMigrateToNewAccessGroup(key: key)

        // Try to read the item again with updated accessibility
        var readQuery = buildBaseServiceQuery(for: key)
        readQuery[kSecReturnData] = true

        var item: CFTypeRef?
        let readStatus = secItem.copyMatching(readQuery as CFDictionary, &item)

        if readStatus == errSecSuccess, let data = item as? Data {
            return data
        } else {
            return nil
        }
    }

    private func tryToMigrateKeyToNewAccessGroupOnUpdate(data: Data, key: String) throws {

        tryToMigrateToNewAccessGroup(key: key)

        let updateQuery = buildBaseServiceQuery(for: key)
        let updateAttributes = [kSecValueData: data]

        let updateStatus = secItem.update(updateQuery as CFDictionary, updateAttributes as CFDictionary)

        guard updateStatus == errSecSuccess else {
            throw KeychainError.itemNotFound
        }
    }

    private func tryToMigrateToNewAccessGroup(key: String) {
        var query = buildBaseServiceQuery(for: key)
        query.removeValue(forKey: kSecAttrAccessGroup)

        let attributesToUpdate = [
            kSecAttrAccessGroup: accessGroup
        ] as [CFString: Any]

        let _ = secItem.update(query as CFDictionary, attributesToUpdate as CFDictionary)
    }
}
