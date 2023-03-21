import Foundation
import XCTest
@testable import WalletConnectRelay
@testable import WalletConnectJWT

final class JWTTests: XCTestCase {
    let expectedJWT =  "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2NTY5MTAwOTcsImV4cCI6MTY1Njk5NjQ5NywiaXNzIjoiZGlkOmtleTp6Nk1rb2RIWnduZVZSU2h0YUxmOEpLWWt4cERHcDF2R1pucEdtZEJwWDhNMmV4eEgiLCJzdWIiOiJjNDc5ZmU1ZGM0NjRlNzcxZTc4YjE5M2QyMzlhNjViNThkMjc4Y2FkMWMzNGJmYjBiNTcxNmU1YmI1MTQ5MjhlIiwiYXVkIjoid3NzOi8vcmVsYXkud2FsbGV0Y29ubmVjdC5jb20ifQ.0JkxOM-FV21U7Hk-xycargj_qNRaYV2H5HYtE4GzAeVQYiKWj7YySY5AdSqtCgGzX4Gt98XWXn2kSr9rE1qvCA"

    func testJWTEncoding() {
        var jwt = JWT(claims: RelayAuthPayload.Claims.stub())
        let signer = EdDSASignerMock()
        signer.signature = "0JkxOM-FV21U7Hk-xycargj_qNRaYV2H5HYtE4GzAeVQYiKWj7YySY5AdSqtCgGzX4Gt98XWXn2kSr9rE1qvCA"
        try! jwt.sign(using: signer)
        let encoded = try! jwt.encoded()
        XCTAssertEqual(expectedJWT, encoded)
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
        return RelayAuthPayload.Claims(iss: iss, sub: sub, aud: aud, iat: iat, exp: exp)
    }
}
