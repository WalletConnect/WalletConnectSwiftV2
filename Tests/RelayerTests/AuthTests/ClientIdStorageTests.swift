import Foundation
import XCTest
import TestingUtils
import WalletConnectKMS
@testable import WalletConnectRelay

final class ClientIdStorageTests: XCTestCase {

    var sut: ClientIdStorage!
    var keychain: KeychainStorageMock!
    var standardDefaults = UserDefaults.standard
    var groupDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        keychain = KeychainStorageMock()
        groupDefaults = UserDefaults(suiteName: "group")!
        sut = ClientIdStorage(defaults: groupDefaults, keychain: keychain, logger: ConsoleLoggerMock())
    }

    override func tearDown() {
        super.tearDown()
        groupDefaults.removePersistentDomain(forName: "group")
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }

    func testGetOrCreate() throws {
        XCTAssertThrowsError(try keychain.read(key: "com.walletconnect.iridium.client_id") as SigningPrivateKey)

        let saved = try sut.getOrCreateKeyPair()
        let storageId = saved.publicKey.rawRepresentation.sha256().toHexString()
        XCTAssertEqual(saved, try keychain.read(key: storageId))

        let restored = try sut.getOrCreateKeyPair()
        XCTAssertEqual(saved, restored)
    }

    func testGetClientId() throws {
        let didKey = try DIDKey(did: "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH")

        /// Initial state
        XCTAssertThrowsError(try sut.getClientId())

        let privateKey = try SigningPrivateKey(rawRepresentation: didKey.rawData)

        groupDefaults.set(privateKey.publicKey.rawRepresentation, forKey: "com.walletconnect.iridium.client_id.public")

        /// Private part not found
        XCTAssertThrowsError(try sut.getClientId())

        let storageId = privateKey.publicKey.rawRepresentation.sha256().toHexString()
        try keychain.add(privateKey, forKey: storageId)

        let clientId = try sut.getClientId()
        let didPublicKey = DIDKey(rawData: privateKey.publicKey.rawRepresentation)

        XCTAssertEqual(clientId, didPublicKey.did(variant: .ED25519))
    }

    // This test covers the scenario where both parts of the key are in the keychain, and the public part needs to be moved to the group defaults.
    func testMigrationFromFullKeychain() throws {
        let clientId = SigningPrivateKey()

        try keychain.add(clientId, forKey: "com.walletconnect.iridium.client_id")

        // Migration on init
        let clientIdStorage = ClientIdStorage(defaults: groupDefaults, keychain: keychain, logger: ConsoleLoggerMock())

        let publicPartData = groupDefaults.data(forKey: "com.walletconnect.iridium.client_id.public")!
        let publicPart = try SigningPublicKey(rawRepresentation: publicPartData)

        let privatePartStorageId = publicPart.rawRepresentation.sha256().toHexString()
        let privatePart: SigningPrivateKey = try keychain.read(key: privatePartStorageId)

        XCTAssertEqual(publicPart, clientId.publicKey)
        XCTAssertEqual(privatePart, clientId)

        let oldClientId: SigningPrivateKey? = try? keychain.read(key: "com.walletconnect.iridium.client_id")
        XCTAssertNil(oldClientId)

        let restoredPrivatePart = try clientIdStorage.getOrCreateKeyPair()
        XCTAssertEqual(restoredPrivatePart, clientId)

        let restoredPublicPart = try clientIdStorage.getClientId()
        XCTAssertEqual(restoredPublicPart, DIDKey(rawData: clientId.publicKey.rawRepresentation).did(variant: .ED25519))
    }

    // This test simulates users who were affected by the last migration, where the public part is in the standard UserDefaults and needs to be migrated to the group defaults.
    func testClientsAffectedByKeychainToDefaultsMigration() throws {

        let publicStorageKey = "com.walletconnect.iridium.client_id.public"

        // Setup: Affected by last migration (public key in standard UserDefaults)
        let clientId = SigningPrivateKey()
        standardDefaults.set(clientId.publicKey.rawRepresentation, forKey: publicStorageKey)

        // Migration on init
        let _ = ClientIdStorage(defaults: groupDefaults, keychain: keychain, logger: ConsoleLoggerMock())

        // Validate: Public key should be migrated to group defaults
        let publicPartData = groupDefaults.data(forKey: publicStorageKey)!
        let publicPart = try SigningPublicKey(rawRepresentation: publicPartData)
        XCTAssertEqual(publicPart, clientId.publicKey)
    }

    // This test verifies the scenario where the public part of the key is already in the group defaults and has never been migrated. It checks that no migration occurs and the migration flag remains unset.
    func testNeverMigratedWithPubPartInGroupDefaultsAndCheckMigrationFlag() throws {
        let publicStorageKey = "com.walletconnect.iridium.client_id.public"
        let migrationFlagKey = "com.walletconnect.has_migrated_public_key_to_group"

        // Setup: Public key already in group defaults and no migration flag set
        let clientId = SigningPrivateKey()
        groupDefaults.set(clientId.publicKey.rawRepresentation, forKey: publicStorageKey)
        XCTAssertFalse(groupDefaults.bool(forKey: migrationFlagKey)) // Ensure migration flag is not set

        // Migration on init
        let _ = ClientIdStorage(defaults: groupDefaults, keychain: keychain, logger: ConsoleLoggerMock())

        // Validate: No migration needed, public key remains in group defaults
        let publicPartData = groupDefaults.data(forKey: publicStorageKey)!
        let publicPart = try SigningPublicKey(rawRepresentation: publicPartData)
        XCTAssertEqual(publicPart, clientId.publicKey)

        // Check that the migration flag remains unset, indicating no migration occurred
        XCTAssertFalse(groupDefaults.bool(forKey: migrationFlagKey))
    }

    // This test ensures that for users who have already undergone the migration process, no additional migration occurs. It checks that the existing keys remain unchanged and the migration flag is set.
    func testAlreadyMigrated() throws {
        let publicStorageKey = "com.walletconnect.iridium.client_id.public"
        let migrationFlagKey = "com.walletconnect.has_migrated_public_key_to_group"

        let clientId = SigningPrivateKey()

        let storageId = clientId.publicKey.rawRepresentation.sha256().toHexString()

        try keychain.add(clientId, forKey: storageId)
        groupDefaults.set(clientId.publicKey.rawRepresentation, forKey: publicStorageKey)
        groupDefaults.set(true, forKey: migrationFlagKey)

        // Migration on init
        let _ = ClientIdStorage(defaults: groupDefaults, keychain: keychain, logger: ConsoleLoggerMock())

        // Validate: No change in data, keys remain same
        let publicPartData = groupDefaults.data(forKey: publicStorageKey)!
        let publicPart = try SigningPublicKey(rawRepresentation: publicPartData)
        XCTAssertEqual(publicPart, clientId.publicKey)

        let privatePart: SigningPrivateKey = try keychain.read(key: storageId)
        XCTAssertEqual(privatePart, clientId)
    }
}
