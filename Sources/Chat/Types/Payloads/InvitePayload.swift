import Foundation

struct InvitePayload: JWTClaimsCodable {

    struct Wrapper: JWTWrapper {
        let inviteAuth: String

        init(jwtString: String) {
            self.inviteAuth = jwtString
        }

        var jwtString: String {
            return inviteAuth
        }
    }

    struct Claims: JWTClaims {
        let iss: String
        let iat: UInt64
        let exp: UInt64
        let ksu: String

        let aud: String // responder/invitee blockchain account (did:pkh)
        let sub: String // opening message included in the invite
        let pke: String // proposer/inviter public key (did:key)
    }

    let keyserver: URL
    let message: String
    let inviteeAccount: Account
    let inviterPublicKey: DIDKey

    init(keyserver: URL, message: String, inviteeAccount: Account, inviterPublicKey: DIDKey) {
        self.keyserver = keyserver
        self.message = message
        self.inviteeAccount = inviteeAccount
        self.inviterPublicKey = inviterPublicKey
    }

    init(claims: Claims) throws {
        self.keyserver = try claims.ksu.asURL()
        self.message = claims.sub
        self.inviteeAccount = try Account(DIDPKHString: claims.aud)
        self.inviterPublicKey = try DIDKey(did: claims.pke)
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iss: iss,
            iat: defaultIatMilliseconds(),
            exp: expiry(days: 30),
            ksu: keyserver.absoluteString,
            aud: inviteeAccount.did,
            sub: message,
            pke: inviterPublicKey.did(prefix: true, variant: .X25519)
        )
    }
}
