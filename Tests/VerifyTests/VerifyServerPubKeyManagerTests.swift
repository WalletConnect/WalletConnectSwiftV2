import XCTest
import CryptoKit
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
        let expectedJWK = VerifyServerPublicKey.JWK.stub()
        let expectedPublicKey = try expectedJWK.P256SigningPublicKey()
        let expiresAt = Date().timeIntervalSince1970 + 3600 // 1 hour from now
        fetcher.publicKey = VerifyServerPublicKey(publicKey: expectedJWK, expiresAt: expiresAt)
        manager = VerifyServerPubKeyManager(store: store, fetcher: fetcher)

        let publicKey = try await manager.getPublicKey()

        XCTAssertEqual(publicKey.rawRepresentation, expectedPublicKey.rawRepresentation)
    }

    func testGetPublicKeyFromLocalStorage() async throws {
        let expectedJWK = VerifyServerPublicKey.JWK.stub()
        let expectedPublicKey = try expectedJWK.P256SigningPublicKey()
        let expiresAt = Date().timeIntervalSince1970 + 3600 // 1 hour from now
        let storedKey = VerifyServerPublicKey(publicKey: expectedJWK, expiresAt: expiresAt)
        store.set(storedKey, forKey: VerifyServerPubKeyManager.publicKeyStorageKey)
        manager = VerifyServerPubKeyManager(store: store, fetcher: fetcher)

        let publicKey = try await manager.getPublicKey()

        XCTAssertEqual(publicKey.rawRepresentation, expectedPublicKey.rawRepresentation)
    }

    func testGetExpiredPublicKeyFromLocalStorage() async throws {
        let oldJWK = VerifyServerPublicKey.JWK.stub()
        let newJWK = VerifyServerPublicKey.JWK(
            crv: "P-256",
            ext: true,
            keyOps: ["verify"],
            kty: "EC",
            x: "MKl2ZQXTZsL10tK3nDXJZUJTTkGaxgPtg42lC5VxW9c",
            y: "IcIsyFf6M5XzUjxwK9ujYB69TUMzIYGTkUyrvjoB3UM"
        )
        let oldPublicKey = try oldJWK.P256SigningPublicKey()
        let newPublicKey = try newJWK.P256SigningPublicKey()
        let expiredTime = Date().timeIntervalSince1970 - 3600 // 1 hour ago
        let validTime = Date().timeIntervalSince1970 + 3600 // 1 hour from now
        let storedKey = VerifyServerPublicKey(publicKey: oldJWK, expiresAt: expiredTime)
        store.set(storedKey, forKey: VerifyServerPubKeyManager.publicKeyStorageKey)

        fetcher.publicKey = VerifyServerPublicKey(publicKey: newJWK, expiresAt: validTime)
        manager = VerifyServerPubKeyManager(store: store, fetcher: fetcher)

        let publicKey = try await manager.getPublicKey()

        XCTAssertEqual(publicKey.rawRepresentation, newPublicKey.rawRepresentation)
    }
}

extension VerifyServerPublicKey.JWK {
    static func stub() -> VerifyServerPublicKey.JWK {
        return VerifyServerPublicKey.JWK(
            crv: "P-256",
            ext: true,
            keyOps: ["verify"],
            kty: "EC",
            x: "CbL4DOYOb1ntd-8OmExO-oS0DWCMC00DntrymJoB8tk",
            y: "KTFwjHtQxGTDR91VsOypcdBfvbo6sAMj5p4Wb-9hRA0"
        )
    }
}
