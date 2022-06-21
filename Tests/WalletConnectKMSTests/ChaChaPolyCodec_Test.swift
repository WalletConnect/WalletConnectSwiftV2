import Foundation
import XCTest
@testable import WalletConnectKMS
import CryptoKit

class ChaChaPolyCodec_Test: XCTestCase {
    let message = "Test Message"
    var codec: ChaChaPolyCodec!
    let symmetricKey = Data(hex: "0653ca620c7b4990392e1c53c4a51c14a2840cd20f0f1524cf435b17b6fe988c")

    override func setUp() {
        codec = ChaChaPolyCodec()
    }

    override func tearDown() {
        codec = nil
    }

    func testEncodeDecode() {
        let encryptionPayload = try! codec.encode(plaintext: message, symmetricKey: symmetricKey)
        let decodedMessage = try! codec.decode(sealbox: encryptionPayload, symmetricKey: symmetricKey)
        XCTAssertEqual(message, String(decoding: decodedMessage, as: UTF8.self))
    }

    func testThrowErrorOnMalformedSealbox() {
        var encryptionPayload = try! codec.encode(plaintext: message, symmetricKey: symmetricKey)
        encryptionPayload.append(contentsOf: [1])
        XCTAssertThrowsError(try codec.decode(sealbox: encryptionPayload, symmetricKey: symmetricKey))
    }

    func testNotThrowOnAuthenticCiphertext() {
        let encryptedPayload = try! codec.encode(plaintext: message, symmetricKey: symmetricKey)
        XCTAssertNoThrow(try codec.decode(sealbox: encryptedPayload, symmetricKey: symmetricKey))
    }

    // MARK: - Tests cohesion with Kotlin and JS

    func testEncodeCohesion() {
        let plaintext = "WalletConnect"
        let nonceString = "qwecfaasdads"
        let nonce = try! ChaChaPoly.Nonce(data: nonceString.data(using: .utf8)!)
        let serializedMessage = try! codec.encode(plaintext: plaintext, symmetricKey: symmetricKey, nonce: nonce).base64EncodedString()
        XCTAssertEqual(serializedMessage, "cXdlY2ZhYXNkYWRzVhkbjHqli8hN0rFbAtMPIsJho4zLvWskMTQKSGw=")
    }

    func testDecodeCohesion() {
        let combinedSealBox = Data(base64Encoded: "cXdlY2ZhYXNkYWRzVhkbjHqli8hN0rFbAtMPIsJho4zLvWskMTQKSGw=")!
        let decryptedData = try! codec.decode(sealbox: combinedSealBox, symmetricKey: symmetricKey)
        print("decrypted data \(decryptedData.base64EncodedString())")
        let plaintext = String(decoding: decryptedData, as: UTF8.self)
        XCTAssertEqual(plaintext, "WalletConnect")
    }
}
