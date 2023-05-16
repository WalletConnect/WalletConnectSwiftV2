
import Foundation

public class ClientIdMigrationController {

    private let service: String

    private let secItem: KeychainServiceProtocol

    private let keyValueStorage: KeyValueStorage

    private let lastMigrationKey = "com.walletconnect.iridium.last_client_id_migration"

    private let clientIdStorageKey = "com.walletconnect.iridium.client_id"

    private let logger: ConsoleLogging

    public init(
        keychainService: KeychainServiceProtocol = KeychainServiceWrapper(),
        serviceIdentifier: String,
        keyValueStorage: KeyValueStorage,
        logger: ConsoleLogging
    ) {
        self.secItem = keychainService
        self.keyValueStorage = keyValueStorage
        self.logger = logger
        service = serviceIdentifier
    }

    func migrateIfNeeded() {
        if let lastMigration = keyValueStorage.object(forKey: lastMigrationKey) as? String {
            logger.debug("last migration: \(lastMigration)")
            return
        }

        logger.debug("ClientIdMigrationController: Migrating client id")
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrIsInvisible: true,
            kSecUseDataProtectionKeychain: true,
            kSecAttrService: service,
            kSecAttrAccount: clientIdStorageKey
        ]
        let attributes = [kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]

        let status = secItem.update(query as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            logger.debug(status)
            return
        }
        logger.debug("Migrated client Id")

        keyValueStorage.set(EnvironmentInfo.packageVersion, forKey: lastMigrationKey)
    }

}
