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

    func testGetClientId() {
        let did = "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH"
        didKeyFactory.did = did
        _ = try! sut.getOrCreateKeyPair()

        let clientId = try! sut.getClientId()
        XCTAssertEqual(did, clientId)

    }
}
