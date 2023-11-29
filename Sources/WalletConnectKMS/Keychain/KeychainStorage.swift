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
        var query = buildBaseServiceQuery(for: key, accessGroup: accessGroup)
        query[kSecReturnData] = true

        var item: CFTypeRef?
        let status = secItem.copyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return try synchronizationQueue.sync {
                // Try to update the accessibility attribute first
                tryUpdateAccessibilityAttribute(key: key)
                // Then attempt to migrate to the new access group and return if item exists
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
            try tryMigrateAttrAccessibleOnUpdate(data: data, key: key) // TODO: Remove once migration period ends
        default:
            throw KeychainError(status)
        }
    }

    public func delete(key: String) throws {
        let query = buildBaseServiceQuery(for: key, accessGroup: accessGroup)

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

    private func buildBaseServiceQuery(for key: String, accessGroup: String? = nil) -> [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrIsInvisible: true,
            kSecUseDataProtectionKeychain: true,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup] = accessGroup
        }

        return query
    }


    private func tryUpdateAccessibilityAttribute(key: String) {
        var updateQuery = buildBaseServiceQuery(for: key)
        updateQuery[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let attributes = [kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let status = secItem.update(updateQuery as CFDictionary, attributes as CFDictionary)

        if status == errSecSuccess {
            print("Successfuly migrated with kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly")
        } else {
            print("Item for query not found, item potentially already migrated with kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly")
        }
    }

    private func tryToMigrateKeyToNewAccessGroupOnRead(key: String) throws -> Data? {
        // Update the item to include the new access group
        let query = buildBaseServiceQuery(for: key)
        let attributesToUpdate = [
            kSecAttrAccessGroup: accessGroup
        ] as [CFString: Any]

        let updateStatus = secItem.update(query as CFDictionary, attributesToUpdate as CFDictionary)

        print("Migrate Key To New Access Group status: \(updateStatus)")
        guard updateStatus == errSecSuccess else {
            throw KeychainError(updateStatus)
        }
        // Try to read the item again with updated accessibility
        var readQuery = buildBaseServiceQuery(for: key, accessGroup: accessGroup)
        readQuery[kSecReturnData] = true

        var item: CFTypeRef?
        let readStatus = secItem.copyMatching(readQuery as CFDictionary, &item)

        if readStatus == errSecSuccess, let data = item as? Data {
            return data
        } else {
            return nil
        }
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
