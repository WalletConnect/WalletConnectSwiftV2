
import Foundation
import XCTest
@testable import WalletConnectKMS

class AES_256_CBC_HMAC_SHA256_Codec_Test: XCTestCase {
    let message = "Test Message"
    var codec: AES_256_CBC_HMAC_SHA256_Codec!
    let symmetricKey = try! SymmetricKey(hex: "404D635166546A576E5A7234753777217A25432A462D4A614E645267556B5870")

    override func setUp() {
        codec = AES_256_CBC_HMAC_SHA256_Codec()
    }

    override func tearDown() {
        codec = nil
    }

    func testEncodeDecode() {
        let encryptionPayload = try! codec.encode(plainText: message, symmetricKey: symmetricKey)
        let decodedMessage = try! codec.decode(payload: encryptionPayload, symmetricKey: symmetricKey)
        XCTAssertEqual(message, decodedMessage)
    }
    
    func testThrowErrorOnUnauthenticCiphertext() {
        var encryptedPayload = try! codec.encode(plainText: message, symmetricKey: symmetricKey)
        encryptedPayload.cipherText.append(Data(hex: "123"))
        XCTAssertThrowsError(try codec.decode(payload: encryptedPayload, symmetricKey: symmetricKey))
    }
    
    func testNotThrowOnAuthenticCiphertext() {
        let encryptedPayload = try! codec.encode(plainText: message, symmetricKey: symmetricKey)
        XCTAssertNoThrow(try codec.decode(payload: encryptedPayload, symmetricKey: symmetricKey))
    }
}
