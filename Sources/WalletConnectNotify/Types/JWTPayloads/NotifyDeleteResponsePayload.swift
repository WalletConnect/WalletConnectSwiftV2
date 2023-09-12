import Foundation

struct NotifyDeleteResponsePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Description of action intent. Must be equal to `notify_delete_response`
        let act: String?

        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used
        let iss: String
        /// `did:key` of an identity key. Enables to resolve attached blockchain account.
        let aud: String
        /// Blockchain account that notify subscription has been proposed for -`did:pkh`
        let sub: String
        /// Dapp's domain url
        let app: String

        static var action: String? {
            return "notify_delete_response"
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
    let app: DIDWeb

    init(claims: Claims) throws {
        self.account = try Account(DIDPKHString: claims.sub)
        self.selfPubKey = try DIDKey(did: claims.aud)
        self.app = try DIDWeb(did: claims.app)
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1),
            act: Claims.action,
            iss: iss,
            aud: selfPubKey.did(variant: .ED25519),
            sub: account.did,
            app: app.did
        )
    }
}
