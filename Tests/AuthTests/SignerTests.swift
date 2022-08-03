import Foundation
import XCTest
@testable import Auth
import secp256k1

class SignerTest: XCTestCase {

    private let signer = Signer()

    private let message = "Message".data(using: .utf8)!
    private let privateKey = Data(base64Encoded: "bm2GjW0qNRFXv+ezXRx5U3+7VLTKS0o5/iXYMzjI6Xo=")!
    private let publicKey = Data(base64Encoded: "AxffejKffsmnVBI0fKJ6KPlg6eON+T8ds0ZMlheo6QOg")!
    private let signature = Data(base64Encoded: "AGZT3nnrhkXdHMivRbnakJMUUXVwUtxMeNy/DWvHq87sgSVu+NbShQJVaBbfYG83A3BOaT+cpNJQuUnTv/MEUwE=")!

    private var address: String {
        return try! SignerAddress.from(publicKey: publicKey)
    }

    func testValidSignature() throws {
        let result = try signer.sign(message: message, with: privateKey)

        XCTAssertEqual(signature, result)
        XCTAssertTrue(try signer.isValid(signature: result, message: message, address: address))
    }

    func testInvalidMessage() throws {
        let message = "Message One".data(using: .utf8)!

        XCTAssertFalse(try signer.isValid(signature: signature, message: message, address: address))
    }

    func testInvalidPubKey() throws {
        let address = try SignerAddress.from(publicKey: .randomBytes(count: 32))

        XCTAssertFalse(try signer.isValid(signature: signature, message: message, address: address))
    }

    func testInvalidSignature() throws {
        let signature = Data(base64Encoded: "U5BxHfW0zjTeoAqT3f3U45djb2pom3GwN6tZKc7yHg1onDBJ/YoZlkQOl3E641zHRu5XKOaSY2jj+IqaNoREIwA=")!

        XCTAssertFalse(try signer.isValid(signature: signature, message: message, address: address))
    }

    func testSignerAddressFromPublicKey() throws {
        let publicKey = Data(hex: "aa931f5ee58735270821b3722866d8882d1948909532cf8ac2b3ef144ae8043363d1d3728b49f10c7cd78c38289c8012477473879f3b53169f2a677b7fbed0c7")

        XCTAssertEqual(try SignerAddress.from(publicKey: publicKey), "0xe16c1623c1aa7d919cd2241d8b36d9e79c1be2a2")
    }

    func testSignerAddressFomIss() throws {
        let iss = "did:pkh:eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07"

        XCTAssertEqual(try SignerAddress.from(iss: iss), "0xbac675c310721717cd4a37f6cbea1f081b1c2a07")
    }
}
