import Foundation

struct NotifyWatchSubscriptionsResponsePayload: JWTClaimsCodable {
    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Description of action intent. Must be equal to `notify_watch_subscriptions_response`
        let act: String?

        /// `did:key` of Notify Server authentication key
        let iss: String
        /// `did:key` of an identity key.
        let aud: String
        /// array of Notify Subscriptions
        let sbs: [NotifyServerSubscription]

        static var action: String? {
            return "notify_watch_subscriptions_response"
        }
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

    let subscriptions: [NotifyServerSubscription]
    let selfIdentityKey: DIDKey

    init(claims: Claims) throws {
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
