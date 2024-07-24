import Foundation
import XCTest
@testable import WalletConnectVerify

class VerifyServerPubKeyManagerTests: XCTestCase {
    var manager: VerifyServerPubKeyManager!
    var store: CodableStore<VerifyServerPublicKey>!
    var fetcher: MockPublicKeyFetcher!

    override func setUp() {
        super.setUp()
        let storage = RuntimeKeyValueStorage()
        store = CodableStore<VerifyServerPublicKey>(defaults: storage, identifier: "test")
        fetcher = MockPublicKeyFetcher()
    }

    func testGetPublicKeyFromServer() async throws {
        let expectedPublicKey = "test_public_key"
        let expiresAt = Date().timeIntervalSince1970 + 3600 // 1 hour from now
        fetcher.publicKey = VerifyServerPublicKey(publicKey: expectedPublicKey, expiresAt: expiresAt)
        manager = VerifyServerPubKeyManager(store: store, fetcher: fetcher)

        let publicKey = try await manager.getPublicKey()

        XCTAssertEqual(publicKey, expectedPublicKey)
    }

    func testGetPublicKeyFromLocalStorage() async throws {
        let expectedPublicKey = "test_public_key"
        let expiresAt = Date().timeIntervalSince1970 + 3600 // 1 hour from now
        let storedKey = VerifyServerPublicKey(publicKey: expectedPublicKey, expiresAt: expiresAt)
        store.set(storedKey, forKey: VerifyServerPubKeyManager.publicKeyStorageKey)
        manager = VerifyServerPubKeyManager(store: store, fetcher: fetcher)

        let publicKey = try await manager.getPublicKey()

        XCTAssertEqual(publicKey, expectedPublicKey)
    }

    func testGetExpiredPublicKeyFromLocalStorage() async throws {
        let expectedPublicKey = "test_public_key"
        let newTestPubKey = "new_test_public_key"
        let expiresAt = Date().timeIntervalSince1970 - 3600 // 1 hour ago
        let storedKey = VerifyServerPublicKey(publicKey: expectedPublicKey, expiresAt: expiresAt)
        store.set(storedKey, forKey: VerifyServerPubKeyManager.publicKeyStorageKey)

        fetcher.publicKey = VerifyServerPublicKey(publicKey: newTestPubKey, expiresAt: Date().timeIntervalSince1970 + 3600)
        manager = VerifyServerPubKeyManager(store: store, fetcher: fetcher)

        let publicKey = try await manager.getPublicKey()

        XCTAssertEqual(publicKey, newTestPubKey)
    }
}
