import Foundation
import XCTest
import WalletConnectKMS
@testable import WalletConnectRelay

final class EdDSASignerTests: XCTestCase {
    var sut: EdDSASigner!

    func testSign() {
        let keyRaw = Data(hex: "58e0254c211b858ef7896b00e3f36beeb13d568d47c6031c4218b87718061295")
        let signingKey = try! SigningPrivateKey(rawRepresentation: keyRaw)
        sut = EdDSASigner(signingKey)
        let header = try! JWT.Header(alg: "EdDSA").encode()
        let claims = try! JWT.Claims(
            iss: "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH",
            sub: "c479fe5dc464e771e78b193d239a65b58d278cad1c34bfb0b5716e5bb514928e")
            .encode()
        let signature = try! sut.sign(header: header, claims: claims)
        XCTAssertNotNil(signature)
    }
}
