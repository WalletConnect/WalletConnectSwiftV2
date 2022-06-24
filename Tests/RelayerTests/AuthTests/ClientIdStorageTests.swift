import Foundation
import XCTest
import TestingUtils
import WalletConnectKMS
@testable import WalletConnectRelay

final class ClientIdStorageTests: XCTestCase {

    func testGetOrCreate() async throws {
        let keychain = KeychainStorageMock()
        let storage = ClientIdStorage(keychain: keychain)

        XCTAssertThrowsError(try keychain.read(key: "signingPrivateKey") as SigningPrivateKey)

        let saved = try await storage.getOrCreateKeyPair()
        XCTAssertEqual(saved, try keychain.read(key: "signingPrivateKey"))

        let restoredAgain = try await storage.getOrCreateKeyPair()
        XCTAssertEqual(saved, restoredAgain)
    }
}
