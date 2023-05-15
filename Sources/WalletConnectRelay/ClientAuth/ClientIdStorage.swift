import Foundation

public protocol ClientIdStoring {
    func getOrCreateKeyPair() throws -> SigningPrivateKey
    func getClientId() throws -> String
}

public struct ClientIdStorage: ClientIdStoring {
    private let key = "com.walletconnect.iridium.client_id"
    private let keychain: KeychainStorageProtocol
    private let clientIdMigrationController: ClientIdMigrationController?

    public init(
        keychain: KeychainStorageProtocol,
        clientIdMigrationController: ClientIdMigrationController? = nil
    ) {
        self.keychain = keychain
        self.clientIdMigrationController = clientIdMigrationController
        migrateClientIdIfNeeded()
    }

    public func getOrCreateKeyPair() throws -> SigningPrivateKey {
        do {
            return try keychain.read(key: key)
        } catch {
            let privateKey = SigningPrivateKey()
            try keychain.add(privateKey, forKey: key)
            return privateKey
        }
    }

    public func getClientId() throws -> String {
        let privateKey: SigningPrivateKey = try keychain.read(key: key)
        let pubKey = privateKey.publicKey.rawRepresentation
        return DIDKey(rawData: pubKey).did(variant: .ED25519)
    }

    private func migrateClientIdIfNeeded() {
        clientIdMigrationController?.migrateIfNeeded()
    }
}

public class ClientIdMigrationController {

    private let service: String

    private let secItem: KeychainServiceProtocol

    private let keyValueStorage: KeyValueStorage

    private let lastMigrationKey = "com.walletconnect.iridium.last_client_id_migration"

    private let cleintIdStorageKey = "com.walletconnect.iridium.client_id"

    public init(
        keychainService: KeychainServiceProtocol = KeychainServiceWrapper(),
        serviceIdentifier: String,
        keyValueStorage: KeyValueStorage,
        logger: ConsoleLogging
    ) {
        self.secItem = keychainService
        self.keyValueStorage = keyValueStorage
        service = serviceIdentifier
    }

    func migrateIfNeeded() {
        if let lastMigration = keyValueStorage.object(forKey: lastMigrationKey) as? String {
            print("last migration: \(lastMigration)")
            return
        }

        print("ClientIdMigrationController: Migrating client id")
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrIsInvisible: true,
            kSecUseDataProtectionKeychain: true,
            kSecAttrService: service,
            kSecAttrAccount: cleintIdStorageKey
        ]
        let attributes = [kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]

        let status = secItem.update(query as CFDictionary, attributes as CFDictionary)
        print(status.message)
        guard status == errSecSuccess else {
            print(status)
            return
        }

        keyValueStorage.set(EnvironmentInfo.packageVersion, forKey: lastMigrationKey)
    }

}
