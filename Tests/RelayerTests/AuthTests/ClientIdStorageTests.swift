import Foundation
import XCTest
import TestingUtils
import WalletConnectKMS
@testable import WalletConnectRelay

final class ClientIdStorageTests: XCTestCase {

    var sut: ClientIdStorage!
    var keychain: KeychainStorageMock!
    var defaults: RuntimeKeyValueStorage!

    override func setUp() {
        keychain = KeychainStorageMock()
        defaults = RuntimeKeyValueStorage()
        sut = ClientIdStorage(defaults: defaults, keychain: keychain, logger: ConsoleLoggerMock())
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

        defaults.set(privateKey.publicKey.rawRepresentation, forKey: "com.walletconnect.iridium.client_id.public")

        /// Private part not found
        XCTAssertThrowsError(try sut.getClientId())

        let storageId = privateKey.publicKey.rawRepresentation.sha256().toHexString()
        try keychain.add(privateKey, forKey: storageId)

        let clientId = try sut.getClientId()
        let didPublicKey = DIDKey(rawData: privateKey.publicKey.rawRepresentation)

        XCTAssertEqual(clientId, didPublicKey.did(variant: .ED25519))
    }

    func testMigration() throws {
        let defaults = RuntimeKeyValueStorage()
        let keychain = KeychainStorageMock()
        let clientId = SigningPrivateKey()

        try keychain.add(clientId, forKey: "com.walletconnect.iridium.client_id")

        // Migration on init
        let clientIdStorage = ClientIdStorage(defaults: defaults, keychain: keychain, logger: ConsoleLoggerMock())

        let publicPartData = defaults.data(forKey: "com.walletconnect.iridium.client_id.public")!
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
}
