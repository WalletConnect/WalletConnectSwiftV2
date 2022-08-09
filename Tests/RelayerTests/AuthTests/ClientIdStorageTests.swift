import Foundation
import XCTest
import Toolbox
import WalletConnectKMS
@testable import WalletConnectRelay

final class ClientIdStorageTests: XCTestCase {

    func testGetOrCreate() throws {
        let keychain = KeychainStorageMock()
        let storage = ClientIdStorage(keychain: keychain)

        XCTAssertThrowsError(try keychain.read(key: "com.walletconnect.iridium.client_id") as SigningPrivateKey)

        let saved = try storage.getOrCreateKeyPair()
        XCTAssertEqual(saved, try keychain.read(key: "com.walletconnect.iridium.client_id"))

        let restored = try storage.getOrCreateKeyPair()
        XCTAssertEqual(saved, restored)
    }
}
