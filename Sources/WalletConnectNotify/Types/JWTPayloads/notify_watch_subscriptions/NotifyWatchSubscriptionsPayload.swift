import Foundation

struct NotifyWatchSubscriptionsPayload: JWTClaimsCodable {
    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Key server URL
        let ksu: String
        /// Description of action intent. Must be equal to `notify_watch_subscriptions`
        let act: String?

        /// `did:key` of an identity key. Enables to resolve attached blockchain account.
        let iss: String
        /// `did:key` of an identity key.
        let aud: String
        /// Blockchain account that notify subscription has been proposed for -`did:pkh`
        let sub: String

        static var action: String? {
            return "notify_watch_subscriptions"
        }
    }

    struct Wrapper: JWTWrapper {
        let watchSubscriptionsAuth: String

        init(jwtString: String) {
            self.watchSubscriptionsAuth = jwtString
        }

        var jwtString: String {
            return watchSubscriptionsAuth
        }
    }

    let notifyServerIdentityKey: DIDKey
    let keyserver: URL
    let subscriptionAccount: Account

    init(notifyServerAuthenticationKey: DIDKey, keyserver: URL, subscriptionAccount: Account) {
        self.notifyServerIdentityKey = notifyServerAuthenticationKey
        self.keyserver = keyserver
        self.subscriptionAccount = subscriptionAccount
    }

    init(claims: Claims) throws {
        self.notifyServerIdentityKey = try DIDKey(did: claims.aud)
        self.keyserver = try claims.ksu.asURL()
        self.subscriptionAccount = try Account(DIDPKHString: claims.sub)
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 30),
            ksu: keyserver.absoluteString,
            act: Claims.action,
            iss: iss,
            aud: notifyServerIdentityKey.did(variant: .ED25519),
            sub: subscriptionAccount.did
        )
    }
    
}
