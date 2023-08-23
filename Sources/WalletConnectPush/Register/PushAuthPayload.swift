import Foundation

struct PushAuthPayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        let iss: String
        let sub: String
        let aud: String
        let iat: UInt64
        let exp: UInt64

        /// Note: - Mock
        /// Not encodint into json object
        let act: String

        enum CodingKeys: String, CodingKey {
            case iss
            case sub
            case aud
            case iat
            case exp
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(iss, forKey: .iss)
            try container.encode(sub, forKey: .sub)
            try container.encode(aud, forKey: .aud)
            try container.encode(iat, forKey: .iat)
            try container.encode(exp, forKey: .exp)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.iss = try container.decode(String.self, forKey: .iss)
            self.sub = try container.decode(String.self, forKey: .sub)
            self.aud = try container.decode(String.self, forKey: .aud)
            self.iat = try container.decode(UInt64.self, forKey: .iat)
            self.exp = try container.decode(UInt64.self, forKey: .exp)
            self.act = PushAuthPayload.act
        }
    }

    struct Wrapper: JWTWrapper {
        let jwtString: String
    }

    static var act: String {
        return "fake_act"
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
            exp: expiry(days: 1),
            act: Self.act
        )
    }
}
