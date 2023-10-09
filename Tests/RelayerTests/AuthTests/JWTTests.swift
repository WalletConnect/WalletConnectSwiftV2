import Foundation
import XCTest
@testable import WalletConnectRelay
@testable import WalletConnectJWT

final class JWTTests: XCTestCase {
    let expectedJWT =  "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ3c3M6Ly9yZWxheS53YWxsZXRjb25uZWN0LmNvbSIsImV4cCI6MTY1Njk5NjQ5NywiaWF0IjoxNjU2OTEwMDk3LCJpc3MiOiJkaWQ6a2V5Ono2TWtvZEhad25lVlJTaHRhTGY4SktZa3hwREdwMXZHWm5wR21kQnBYOE0yZXh4SCIsInN1YiI6ImM0NzlmZTVkYzQ2NGU3NzFlNzhiMTkzZDIzOWE2NWI1OGQyNzhjYWQxYzM0YmZiMGI1NzE2ZTViYjUxNDkyOGUifQ.0JkxOM-FV21U7Hk-xycargj_qNRaYV2H5HYtE4GzAeVQYiKWj7YySY5AdSqtCgGzX4Gt98XWXn2kSr9rE1qvCA"

    func testJWTEncoding() throws {
        let signer = EdDSASignerMock()
        signer.signature = "0JkxOM-FV21U7Hk-xycargj_qNRaYV2H5HYtE4GzAeVQYiKWj7YySY5AdSqtCgGzX4Gt98XWXn2kSr9rE1qvCA"
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        jsonEncoder.dateEncodingStrategy = .secondsSince1970
        let jwt = try JWT(claims: RelayAuthPayload.Claims.stub(), signer: signer, jsonEncoder: jsonEncoder)
        XCTAssertEqual(expectedJWT, jwt.string)
    }

    func testBase64Encoding() throws {
        let signature = "gf8ZZb04-6DeqhboeA-I7EucdSVuLCJmKcPSTHJqG0CBfVKn0YihgosaD9-6gXED8Itrx5EsyEi49kLmTvS8DA"

        let data = try JWTEncoder.base64urlDecodedData(string: signature)
        let string = JWTEncoder.base64urlEncodedString(data: data)

        XCTAssertEqual(signature, string)
    }
}

extension RelayAuthPayload.Claims {
    static func stub() -> RelayAuthPayload.Claims {
        let iss = "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH"
        let sub = "c479fe5dc464e771e78b193d239a65b58d278cad1c34bfb0b5716e5bb514928e"
        let iatDate = Date(timeIntervalSince1970: 1656910097)
        let iat = UInt64(iatDate.timeIntervalSince1970)
        var components = DateComponents()
        components.setValue(1, for: .day)
        let aud = "wss://relay.walletconnect.com"
        let expDate = Calendar.current.date(byAdding: components, to: iatDate)!
        let exp = UInt64(expDate.timeIntervalSince1970)
        return RelayAuthPayload.Claims(iss: iss, sub: sub, aud: aud, iat: iat, exp: exp, act: nil)
    }
}
