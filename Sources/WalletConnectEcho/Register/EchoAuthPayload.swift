import Foundation
import WalletConnectJWT

struct EchoAuthPayload: JWTClaimsCodable {

    struct Wrapper: JWTWrapper {
        let jwtString: String
    }

    struct Claims: JWTEncodable {
        let iss: String
        let sub: String
        let aud: String
        let iat: Int64
        let exp: Int64
    }

    let subject: String
    let audience: String

    init(subject: String, audience: String) {
        self.subject = subject
        self.audience = audience
    }

    init(claims: Claims) throws {
        self.subject = claims.sub
        self.audience = claims.aud
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iss: iss,
            sub: subject,
            aud: audience,
            iat: defaultIat(),
            exp: expiry(days: 1)
        )
    }
}
