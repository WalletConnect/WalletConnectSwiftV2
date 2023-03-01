import Foundation

struct InviteKeyPayload: JWTClaimsCodable {

    struct Wrapper: JWTWrapper {
        let jwtString: String
    }

    struct Claims: JWTClaims {
        let iss: String
        let sub: String
        let aud: String
        let iat: UInt64
        let exp: UInt64
        let pkh: String
    }

    let keyserver: URL
    let account: Account
    let invitePublicKey: DIDKey

    init(keyserver: URL, account: Account, invitePublicKey: DIDKey) {
        self.keyserver = keyserver
        self.account = account
        self.invitePublicKey = invitePublicKey
    }

    init(claims: Claims) throws {
        self.keyserver = try claims.aud.asURL()
        self.account = try Account(DIDPKHString: claims.pkh)
        self.invitePublicKey = try DIDKey(did: claims.sub)
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iss: iss,
            sub: invitePublicKey.did(prefix: true, variant: .X25519),
            aud: keyserver.absoluteString,
            iat: defaultIatMilliseconds(),
            exp: expiry(days: 30),
            pkh: account.did
        )
    }
}
