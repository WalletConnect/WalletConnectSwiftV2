import Foundation

public protocol ClientIdStoring {
    func getOrCreateKeyPair() throws -> SigningPrivateKey
    func getClientId() throws -> String
}

public struct ClientIdStorage: ClientIdStoring {
    private let oldStorageKey = "com.walletconnect.iridium.client_id"
    private let publicStorageKey = "com.walletconnect.iridium.client_id.public"
    private static let migrationQueue = DispatchQueue(label: "com.walletconnect.iridium.clientIdStorageMigration")

    private let defaults: KeyValueStorage
    private let keychain: KeychainStorageProtocol
    private let logger: ConsoleLogging

    public init(defaults: KeyValueStorage, keychain: KeychainStorageProtocol, logger: ConsoleLogging) {
        self.defaults = defaults
        self.keychain = keychain
        self.logger = logger

        migrateIfNeeded()
    }

    public func getOrCreateKeyPair() throws -> SigningPrivateKey {
        do {
            let publicPart = try getPublicPart()
            return try getPrivatePart(for: publicPart)
        } catch Errors.privatePartNotFound, Errors.publicPartNotFound {
            let privateKey = SigningPrivateKey()
            try setPrivatePart(privateKey)
            setPublicPart(privateKey.publicKey)
            return privateKey
        } catch {
            throw error
        }
    }

    public func getClientId() throws -> String {
        let pubKey = try getPublicPart()
        let _ = try getPrivatePart(for: pubKey)
        return DIDKey(rawData: pubKey.rawRepresentation).did(variant: .ED25519)
    }
}

private extension ClientIdStorage {

    enum Errors: Error {
        case publicPartNotFound
        case privatePartNotFound
    }

    func migrateIfNeeded() {
        ClientIdStorage.migrationQueue.sync {
            migratePublicKeyToGroupUserDefaultsIfNeeded()
            migrateFromKeychainToKeyValueStorageIfNeeded()
        }
    }

    func migrateFromKeychainToKeyValueStorageIfNeeded() {
        guard let privateKey: SigningPrivateKey = try? keychain.read(key: oldStorageKey) else {
            return
        }
        do {
            try setPrivatePart(privateKey)
            setPublicPart(privateKey.publicKey)
            try keychain.delete(key: oldStorageKey)
            logger.debug("Keychain data migrated to group UserDefaults")
        } catch {
            logger.debug("ClientID migration failed with: \(error.localizedDescription)")
        }
    }

    private func migratePublicKeyToGroupUserDefaultsIfNeeded() {
        let migrationKey = "com.walletconnect.has_migrated_public_key_to_group"
        guard let groupDefaults = defaults as? UserDefaults,
              groupDefaults != UserDefaults.standard,
              !groupDefaults.bool(forKey: migrationKey),
              let pubKeyRaw = UserDefaults.standard.data(forKey: publicStorageKey) else {
            return
        }

        groupDefaults.set(pubKeyRaw, forKey: publicStorageKey)
        groupDefaults.set(true, forKey: migrationKey)
        UserDefaults.standard.removeObject(forKey: publicStorageKey)
        logger.debug("Public key migrated to group UserDefaults")
    }

    func getPublicPart() throws -> SigningPublicKey {
        guard let data = defaults.data(forKey: publicStorageKey) else {
            throw Errors.publicPartNotFound
        }
        return try SigningPublicKey(rawRepresentation: data)
    }

    func setPublicPart(_ newValue: SigningPublicKey) {
        defaults.set(newValue.rawRepresentation, forKey: publicStorageKey)
    }

    func getPrivatePart(for publicPart: SigningPublicKey) throws -> SigningPrivateKey {
        do {
            return try keychain.read(key: publicPart.storageId)
        } catch KeychainError.itemNotFound {
            throw Errors.privatePartNotFound
        } catch {
            throw error
        }
    }

    func setPrivatePart(_ newValue: SigningPrivateKey) throws {
        try keychain.add(newValue, forKey: newValue.publicKey.storageId)
    }
}

private extension SigningPublicKey {

    var storageId: String {
        return rawRepresentation.sha256().toHexString()
    }
}
