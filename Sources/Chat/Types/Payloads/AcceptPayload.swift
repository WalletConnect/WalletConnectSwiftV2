import Foundation

struct AcceptPayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        let iss: String
        let iat: UInt64
        let exp: UInt64
        let ksu: String

        let aud: String // proposer/inviter blockchain account (did:pkh)
        let sub: String // public key sent by the responder/invitee
    }

    struct Wrapper: JWTWrapper {
        let responseAuth: String

        init(jwtString: String) {
            self.responseAuth = jwtString
        }

        var jwtString: String {
            return responseAuth
        }
    }

    let keyserver: URL
    let inviterAccount: Account
    let inviteePublicKey: DIDKey

    init(keyserver: URL, inviterAccount: Account, inviteePublicKey: DIDKey) {
        self.keyserver = keyserver
        self.inviterAccount = inviterAccount
        self.inviteePublicKey = inviteePublicKey
    }

    init(claims: Claims) throws {
        self.keyserver = try claims.ksu.asURL()
        self.inviterAccount = try Account(DIDPKHString: claims.aud)
        self.inviteePublicKey = try DIDKey(did: claims.sub)
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iss: iss,
            iat: defaultIatMilliseconds(),
            exp: expiry(days: 30),
            ksu: keyserver.absoluteString,
            aud: inviterAccount.did,
            sub: inviteePublicKey.did(prefix: true, variant: .X25519)
        )
    }
}
