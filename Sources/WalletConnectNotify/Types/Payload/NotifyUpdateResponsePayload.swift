import Foundation

struct NotifyUpdateResponsePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// timestamp when jwt was issued
        let iat: UInt64
        /// timestamp when jwt must expire
        let exp: UInt64
        /// Key server URL
        let ksu: String
        /// Description of action intent. Must be equal to "notify_update_response"
        let act: String

        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used.
        let iss: String
        /// `did:key` of an identity key. Enables to resolve attached blockchain account.
        let aud: String
        /// Hash of the new subscription payload
        let sub: String
        /// Dapp's domain url
        let app: String
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

    static var act: String {
        return "notify_update_response"
    }

    let keyserver: URL
    let selfPubKey: DIDKey
    let subscriptionHash: String
    let app: String

    init(claims: Claims) throws {
        self.keyserver = try claims.ksu.asURL()
        self.selfPubKey = try DIDKey(did: claims.aud)
        self.subscriptionHash = claims.sub
        self.app = claims.app
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1),
            ksu: keyserver.absoluteString,
            act: Self.act,
            iss: iss,
            aud: selfPubKey.did(variant: .ED25519),
            sub: subscriptionHash,
            app: app
        )
    }
}
