import Foundation
import XCTest
import TestingUtils
import WalletConnectKMS
@testable import WalletConnectRelay

final class ClientIdStorageTests: XCTestCase {

    var sut: ClientIdStorage!
    var keychain: KeychainStorageMock!
    var didKeyFactory: ED25519DIDKeyFactoryMock!

    override func setUp() {
        keychain = KeychainStorageMock()
        didKeyFactory = ED25519DIDKeyFactoryMock()
        sut = ClientIdStorage(keychain: keychain, didKeyFactory: didKeyFactory)
    }

    func testGetOrCreate() throws {
        XCTAssertThrowsError(try keychain.read(key: "com.walletconnect.iridium.client_id") as SigningPrivateKey)

        let saved = try sut.getOrCreateKeyPair()
        XCTAssertEqual(saved, try keychain.read(key: "com.walletconnect.iridium.client_id"))

        let restored = try sut.getOrCreateKeyPair()
        XCTAssertEqual(saved, restored)
    }
}
