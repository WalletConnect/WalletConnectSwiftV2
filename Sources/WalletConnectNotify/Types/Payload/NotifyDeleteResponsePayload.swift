import Foundation

struct NotifyDeleteResponsePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used
        let iss: String
        /// `did:key` of an identity key. Enables to resolve attached blockchain account.
        let aud: String
        /// Description of action intent. Must be equal to `notify_delete_response`
        let act: String
        /// Hash of the existing subscription payload
        let sub: String
        /// Dapp's domain url
        let app: String
    }

    struct Wrapper: JWTWrapper {
        let deleteAuth: String

        init(jwtString: String) {
            self.deleteAuth = jwtString
        }

        var jwtString: String {
            return deleteAuth
        }
    }

    let accountIdentityKey: DIDKey
    let subscriptionHash: String
    let app: String

    init(
        accountIdentityKey: DIDKey,
        subscriptionHash: String,
        app: String
    ) {
        self.accountIdentityKey = accountIdentityKey
        self.subscriptionHash = subscriptionHash
        self.app = app
    }

    init(claims: Claims) throws {
        self.accountIdentityKey = try DIDKey(did: claims.aud)
        self.subscriptionHash = claims.sub
        self.app = claims.app
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1),
            iss: iss,
            aud: accountIdentityKey.did(variant: .ED25519),
            act: "notify_delete_response",
            sub: subscriptionHash,
            app: app
        )
    }
}
