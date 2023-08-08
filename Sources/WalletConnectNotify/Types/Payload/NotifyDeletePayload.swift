import Foundation

struct NotifyDeletePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// `did:key` of an identity key. Enables to resolve attached blockchain account.
        let iss: String
        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used.
        let aud: String
        /// Description of action intent. Must be equal to `notify_delete`
        let act: String
        /// Reason for deleting the subscription
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

    let dappIdentityKey: DIDKey
    let reason: String
    let app: String

    init(
        dappIdentityKey: DIDKey,
        reason: String,
        app: String
    ) {
        self.dappIdentityKey = dappIdentityKey
        self.reason = reason
        self.app = app
    }

    init(claims: Claims) throws {
        self.dappIdentityKey = try DIDKey(did: claims.aud)
        self.reason = claims.sub
        self.app = claims.app
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1),
            iss: iss,
            aud: dappIdentityKey.did(variant: .ED25519),
            act: "notify_delete",
            sub: reason,
            app: app
        )
    }
}
