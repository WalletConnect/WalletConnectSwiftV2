import Foundation

struct NotifySubscriptionsChangedRequestPayload: JWTClaimsCodable {
    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Action intent (must be `notify_subscriptions_changed_request`)
        let act: String?

        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used. diddoc authentication key
        let iss: String
        /// Blockchain account `did:pkh`
        let aud: String
        /// message sent by the author account
        let sub: String
        /// array of Notify Server Subscriptions
        let sbs: [NotifyServerSubscription]

        static var action: String? {
            return "notify_subscriptions_changed"
        }
    }

    struct Wrapper: JWTWrapper {
        let subscriptionsChangedAuth: String

        init(jwtString: String) {
            self.subscriptionsChangedAuth = jwtString
        }

        var jwtString: String {
            return subscriptionsChangedAuth
        }
    }

    let notifyServerAuthenticationKey: DIDKey
    let subscriptions: [NotifyServerSubscription]
    let account: Account

    init(claims: Claims) throws {
        self.notifyServerAuthenticationKey = try DIDKey(did: claims.iss)
        self.subscriptions = claims.sbs
        self.account = try DIDPKH(did: claims.sub).account
    }

    func encode(iss: String) throws -> Claims {
        fatalError("Client is not supposed to encode this JWT payload")
    }
}
