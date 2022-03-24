
import Foundation
import XCTest
@testable import WalletConnectKMS

class ChaChaPolyCodec_Test: XCTestCase {
    let message = "Test Message"
    var codec: ChaChaPolyCodec!
    let symmetricKey = try! SymmetricKey(hex: "404D635166546A576E5A7234753777217A25432A462D4A614E645267556B5870").rawRepresentation

    override func setUp() {
        codec = ChaChaPolyCodec()
    }

    override func tearDown() {
        codec = nil
    }

    func testEncodeDecodeSymKey() {
        let encryptionPayload = try! codec.encode(plaintext: message, symmetricKey: symmetricKey)
        let decodedMessage = try! codec.decode(sealboxString: encryptionPayload, symmetricKey: symmetricKey)
        XCTAssertEqual(message, String(decoding: decodedMessage, as: UTF8.self))
    }
    
    func testEncodeDecodeSharedSecret() {
        
        let sharedSecret =
        
        let encryptionPayload = try! codec.encode(plaintext: message, symmetricKey: symmetricKey)
        let decodedMessage = try! codec.decode(sealboxString: encryptionPayload, symmetricKey: symmetricKey)
        XCTAssertEqual(message, String(decoding: decodedMessage, as: UTF8.self))
    }

    func testThrowErrorOnMalformedSealbox() {
        var encryptionPayload = try! codec.encode(plaintext: message, symmetricKey: symmetricKey)
        encryptionPayload.append("12")
        XCTAssertThrowsError(try codec.decode(sealboxString: encryptionPayload, symmetricKey: symmetricKey))
    }

    func testNotThrowOnAuthenticCiphertext() {
        let encryptedPayload = try! codec.encode(plaintext: message, symmetricKey: symmetricKey)
        XCTAssertNoThrow(try codec.decode(sealboxString: encryptedPayload, symmetricKey: symmetricKey))
    }
}
