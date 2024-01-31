import Foundation

struct NotifyDeletePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Key server URL
        let ksu: String
        /// Description of action intent. Must be equal to `notify_delete`
        let act: String?

        /// `did:key` of an identity key. Enables to resolve attached blockchain account.
        let iss: String
        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used.
        let aud: String
        /// Blockchain account that notify subscription has been proposed for -`did:pkh`
        let sub: String
        /// Dapp's domain url
        let app: String

        static var action: String? {
            return "notify_delete"
        }
    }

    struct Wrapper: JWTWrapper {
        let deleteAuth: String

        init(jwtString: String) {
            self.deleteAuth = jwtString
        }

        var jwtString: String {
            return deleteAuth
        }
    }

    let account: Account
    let keyserver: URL
    let dappPubKey: DIDKey
    let app: DIDWeb

    init(
        account: Account,
        keyserver: URL,
        dappPubKey: DIDKey,
        app: DIDWeb
    ) {
        self.account = account
        self.keyserver = keyserver
        self.dappPubKey = dappPubKey
        self.app = app
    }

    init(claims: Claims) throws {
        self.account = try Account(DIDPKHString: claims.sub)
        self.keyserver = try claims.ksu.asURL()
        self.dappPubKey = try DIDKey(did: claims.aud)
        self.app = try DIDWeb(did: claims.app)
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1),
            ksu: keyserver.absoluteString,
            act: Claims.action,
            iss: iss,
            aud: dappPubKey.did(variant: .ED25519),
            sub: account.did,
            app: app.did
        )
    }
}
