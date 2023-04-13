import Foundation

struct IDAuthPayload: JWTClaimsCodable {

    enum Errors: Error {
        case undefinedKind
    }

    enum Kind: String {
        case registerInvite = "register_invite"
        case unregisterInvite = "unregister_invite"
        case unregisterIdentity = "unregister_identity"

        init(rawValue: String) throws {
            guard let kind = Kind(rawValue: rawValue) else {
                throw Errors.undefinedKind
            }
            self = kind
        }
    }

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
        let act: String
    }

    let kind: Kind
    let keyserver: URL
    let account: Account
    let invitePublicKey: DIDKey

    init(kind: Kind, keyserver: URL, account: Account, invitePublicKey: DIDKey) {
        self.kind = kind
        self.keyserver = keyserver
        self.account = account
        self.invitePublicKey = invitePublicKey
    }

    init(claims: Claims) throws {
        self.kind = try Kind(rawValue: claims.act)
        self.keyserver = try claims.aud.asURL()
        self.account = try Account(DIDPKHString: claims.pkh)
        self.invitePublicKey = try DIDKey(did: claims.sub)
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iss: iss,
            sub: invitePublicKey.did(variant: .X25519),
            aud: keyserver.absoluteString,
            iat: defaultIatMilliseconds(),
            exp: expiry(days: 30),
            pkh: account.did,
            act: kind.rawValue
        )
    }
}
