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
        /// Dapp domain url
        let app: String?

        static var action: String? {
            return "notify_watch_subscriptions"
        }

        // Note: - Overriding `encode(to encoder: Encoder)` implementation to force null app encoding

        enum CodingKeys: CodingKey {
            case iat, exp, ksu, act, iss, aud, sub, app
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: NotifyWatchSubscriptionsPayload.Claims.CodingKeys.self)
            try container.encode(self.iat, forKey: NotifyWatchSubscriptionsPayload.Claims.CodingKeys.iat)
            try container.encode(self.exp, forKey: NotifyWatchSubscriptionsPayload.Claims.CodingKeys.exp)
            try container.encode(self.ksu, forKey: NotifyWatchSubscriptionsPayload.Claims.CodingKeys.ksu)
            try container.encodeIfPresent(self.act, forKey: NotifyWatchSubscriptionsPayload.Claims.CodingKeys.act)
            try container.encode(self.iss, forKey: NotifyWatchSubscriptionsPayload.Claims.CodingKeys.iss)
            try container.encode(self.aud, forKey: NotifyWatchSubscriptionsPayload.Claims.CodingKeys.aud)
            try container.encode(self.sub, forKey: NotifyWatchSubscriptionsPayload.Claims.CodingKeys.sub)
            try container.encode(self.app, forKey: NotifyWatchSubscriptionsPayload.Claims.CodingKeys.app)
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
            sub: subscriptionAccount.did,
            app: nil
        )
    }
    
}
