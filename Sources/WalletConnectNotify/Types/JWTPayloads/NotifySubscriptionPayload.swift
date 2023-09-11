import Foundation

struct NotifySubscriptionPayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Key server URL
        let ksu: String
        /// Description of action intent. Must be equal to `notify_subscription`
        let act: String?

        /// `did:key` of an identity key. Enables to resolve attached blockchain account.
        let iss: String
        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used.
        let aud: String
        /// Blockchain account that notify subscription has been proposed for -`did:pkh`
        let sub: String
        /// Scope of notification types authorized by the user
        let scp: String
        /// Dapp's domain url
        let app: String

        static var action: String? {
            return "notify_subscription"
        }
    }

    struct Wrapper: JWTWrapper {
        let subscriptionAuth: String

        init(jwtString: String) {
            self.subscriptionAuth = jwtString
        }

        var jwtString: String {
            return subscriptionAuth
        }
    }

    let dappPubKey: DIDKey
    let keyserver: URL
    let subscriptionAccount: Account
    let app: DIDWeb
    let scope: String

    init(dappPubKey: DIDKey, keyserver: URL, subscriptionAccount: Account, app: DIDWeb, scope: String) {
        self.dappPubKey = dappPubKey
        self.keyserver = keyserver
        self.subscriptionAccount = subscriptionAccount
        self.app = app
        self.scope = scope
    }

    init(claims: Claims) throws {
        self.dappPubKey = try DIDKey(did: claims.aud)
        self.keyserver = try claims.ksu.asURL()
        self.subscriptionAccount = try Account(DIDPKHString: claims.sub)
        self.app = try DIDWeb(did: claims.app)
        self.scope = claims.scp
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 30),
            ksu: keyserver.absoluteString,
            act: Claims.action,
            iss: iss,
            aud: dappPubKey.did(variant: .ED25519),
            sub: subscriptionAccount.did,
            scp: scope,
            app: app.did
        )
    }
}

