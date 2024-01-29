import Foundation

struct NotifySubscriptionResponsePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// timestamp when jwt was issued
        let iat: UInt64
        /// timestamp when jwt must expire
        let exp: UInt64
        /// Description of action intent. Must be equal to "notify_subscription_response"
        let act: String?

        /// `did:key` of an identity key. Allows for the resolution of which Notify server was used.
        let iss: String
        /// `did:key` of an identity key. Allows for the resolution of the attached blockchain account.
        let aud: String
        /// Blockchain account that notify subscription has been proposed for -`did:pkh`
        let sub: String
        /// Dapp's domain url
        let app: String
        /// array of Notify Subscriptions
        let sbs: [NotifyServerSubscription]

        static var action: String? {
            return "notify_subscription_response"
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

    let account: Account
    let selfPubKey: DIDKey
    let app: String
    let subscriptions: [NotifyServerSubscription]

    init(claims: Claims) throws {
        self.account = try Account(DIDPKHString: claims.sub)
        self.selfPubKey = try DIDKey(did: claims.aud)
        self.app = claims.app
        self.subscriptions = claims.sbs
    }

    func encode(iss: String) throws -> Claims {
        fatalError("Client is not supposed to encode this JWT payload")
    }
}
