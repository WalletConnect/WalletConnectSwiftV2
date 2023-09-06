import Foundation

struct NotifySubscriptionResponsePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// timestamp when jwt was issued
        let iat: UInt64
        /// timestamp when jwt must expire
        let exp: UInt64
        /// Key server URL
        let ksu: String
        /// Description of action intent. Must be equal to "notify_subscription_response"
        let act: String?

        /// `did:key` of an identity key. Allows for the resolution of which Notify server was used.
        let iss: String
        /// `did:key` of an identity key. Allows for the resolution of the attached blockchain account.
        let aud: String
        /// `did:key` of the public key used for key agreement on the Notify topic
        let sub: String
        /// Dapp's domain url
        let app: String

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

    let keyserver: URL
    let selfPubKey: DIDKey
    let publicKey: DIDKey
    let app: String

    init(claims: Claims) throws {
        self.keyserver = try claims.ksu.asURL()
        self.selfPubKey = try DIDKey(did: claims.aud)
        self.publicKey = try DIDKey(did: claims.sub)
        self.app = claims.app
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1),
            ksu: keyserver.absoluteString,
            act: Claims.action,
            iss: iss,
            aud: selfPubKey.did(variant: .ED25519),
            sub: publicKey.did(variant: .X25519),
            app: app
        )
    }
}
