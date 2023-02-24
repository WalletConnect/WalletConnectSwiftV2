import Foundation
import XCTest
import TestingUtils
import WalletConnectKMS
@testable import WalletConnectRelay

final class ClientIdStorageTests: XCTestCase {

    var sut: ClientIdStorage!
    var keychain: KeychainStorageMock!

    override func setUp() {
        keychain = KeychainStorageMock()
        sut = ClientIdStorage(keychain: keychain)
    }

    func testGetOrCreate() throws {
        XCTAssertThrowsError(try keychain.read(key: "com.walletconnect.iridium.client_id") as SigningPrivateKey)

        let saved = try sut.getOrCreateKeyPair()
        XCTAssertEqual(saved, try keychain.read(key: "com.walletconnect.iridium.client_id"))

        let restored = try sut.getOrCreateKeyPair()
        XCTAssertEqual(saved, restored)
    }

    func testGetClientId() throws {
        let didKey = try DIDKey(did: "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH")

        let privateKey = try SigningPrivateKey(rawRepresentation: didKey.rawData)
        try keychain.add(privateKey, forKey: "com.walletconnect.iridium.client_id")

        let clientId = try sut.getClientId()
        let didPublicKey = DIDKey(rawData: privateKey.publicKey.rawRepresentation)
        XCTAssertEqual(clientId, didPublicKey.did(prefix: true, variant: .ED25519))
    }
}
