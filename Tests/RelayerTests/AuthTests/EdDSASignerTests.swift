import Foundation
import XCTest
import WalletConnectKMS
@testable import WalletConnectRelay
@testable import WalletConnectJWT

final class EdDSASignerTests: XCTestCase {
    var sut: EdDSASigner!

    func testSign() {
        let keyRaw = Data(hex: "58e0254c211b858ef7896b00e3f36beeb13d568d47c6031c4218b87718061295")
        let signingKey = try! SigningPrivateKey(rawRepresentation: keyRaw)
        sut = EdDSASigner(signingKey)
        let header = try! JWTHeader(alg: "EdDSA").encode()
        let claims = try! RelayAuthPayload.Claims.stub().encode()
        let signature = try! sut.sign(header: header, claims: claims)
        XCTAssertNotNil(signature)
    }
}
