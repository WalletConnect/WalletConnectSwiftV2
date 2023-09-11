import Foundation

struct NotifyMessageReceiptPayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Key server URL
        let ksu: String
        /// Action intent (must be `notify_message_response`)
        let act: String?

        /// `did:key` of an identity key. Enables to resolve attached blockchain account.
        let iss: String
        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used.
        let aud: String
        /// Hash of the stringified notify message object received
        let sub: String
        /// Dapp's domain url
        let app: String

        static var action: String? {
            return "notify_message_response"
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
    let dappPubKey: DIDKey
    let messageHash: String
    let app: String

    init(
        keyserver: URL,
        dappPubKey: DIDKey,
        messageHash: String,
        app: String
    ) {
        self.keyserver = keyserver
        self.dappPubKey = dappPubKey
        self.messageHash = messageHash
        self.app = app
    }

    init(claims: Claims) throws {
        self.keyserver = try claims.ksu.asURL()
        self.dappPubKey = try DIDKey(did: claims.aud)
        self.messageHash = claims.sub
        self.app = claims.app
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1),
            ksu: keyserver.absoluteString,
            act: Claims.action,
            iss: iss,
            aud: dappPubKey.did(variant: .ED25519),
            sub: messageHash,
            app: app
        )
    }
}
