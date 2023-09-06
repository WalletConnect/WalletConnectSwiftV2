import Foundation

class NotifyWatchSubscriptionsRersponsePayload: JWTClaimsCodable {
    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Description of action intent. Must be equal to `notify_watch_subscriptions`
        let act: String?

        /// `did:key` of Notify Server authentication key
        let iss: String
        /// `did:key` of an identity key.
        let aud: String
        /// array of Notify Subscriptions
        let sbs: [NotifySubscription]

        static var action: String? {
            return "notify_watch_subscriptions"
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

    let subscriptions: [NotifySubscription]
    let selfIdentityKey: DIDKey

    required init(claims: Claims) throws {
        self.selfIdentityKey = try DIDKey(did: claims.aud)
        self.subscriptions = claims.sbs
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 30),
            act: Claims.action,
            iss: iss,
            aud: selfIdentityKey.did(variant: .ED25519),
            sbs: subscriptions
        )
    }

}
