import Foundation

struct NotifyMessageReceiptPayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// `did:key` of an identity key. Enables to resolve attached blockchain account.
        let iss: String
        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used.
        let aud: String
        /// Action intent (must be `notify_receipt`)
        let act: String
        /// Hash of the stringified notify message object received
        let sub: String
        /// Dapp's domain url
        let app: String
    }

    struct Wrapper: JWTWrapper {
        let receiptAuth: String

        init(jwtString: String) {
            self.receiptAuth = jwtString
        }

        var jwtString: String {
            return receiptAuth
        }
    }

    let dappIdentityKey: DIDKey
    let messageHash: String
    let app: String

    init(
        dappIdentityKey: DIDKey,
        messageHash: String,
        app: String
    ) {
        self.dappIdentityKey = dappIdentityKey
        self.messageHash = messageHash
        self.app = app
    }

    init(claims: Claims) throws {
        self.dappIdentityKey = try DIDKey(did: claims.aud)
        self.messageHash = claims.sub
        self.app = claims.app
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1),
            iss: iss,
            aud: dappIdentityKey.did(variant: .ED25519),
            act: "notify_receipt",
            sub: messageHash,
            app: app
        )
    }
}
