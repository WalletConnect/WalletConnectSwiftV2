import Foundation
import XCTest
@testable import WalletConnectRelay

final class JWTTests: XCTestCase {
    let expectedJWT =  "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkaWQ6a2V5Ono2TWtvZEhad25lVlJTaHRhTGY4SktZa3hwREdwMXZHWm5wR21kQnBYOE0yZXh4SCIsInN1YiI6ImM0NzlmZTVkYzQ2NGU3NzFlNzhiMTkzZDIzOWE2NWI1OGQyNzhjYWQxYzM0YmZiMGI1NzE2ZTViYjUxNDkyOGUifQ.0JkxOM-FV21U7Hk-xycargj_qNRaYV2H5HYtE4GzAeVQYiKWj7YySY5AdSqtCgGzX4Gt98XWXn2kSr9rE1qvCA"


    func test() {
        let iss = "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH"
        let sub = "c479fe5dc464e771e78b193d239a65b58d278cad1c34bfb0b5716e5bb514928e"
        let claims = JWT.Claims(iss: iss, sub: sub)
        var jwt = JWT(claims: claims)
        let signer = EdDSASignerMock()
        signer.signature = "0JkxOM-FV21U7Hk-xycargj_qNRaYV2H5HYtE4GzAeVQYiKWj7YySY5AdSqtCgGzX4Gt98XWXn2kSr9rE1qvCA"
        try! jwt.sign(using: signer)
        XCTAssertEqual(expectedJWT, jwt.encoded())
    }

}
class EdDSASignerMock: JWTSigning {
    var alg: String = "EdDSA"

    func sign(header: String, claims: String) throws -> String {
        return signature
    }

    var signature: String!
}
