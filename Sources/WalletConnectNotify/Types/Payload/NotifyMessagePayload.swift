import Foundation

struct NotifyMessagePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Key server URL
        let ksu: String
        /// Action intent (must be `notify_message`)
        let act: String

        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used. diddoc authentication key
        let iss: String
        /// Blockchain account `did:pkh`
        let aud: String
        /// Subscription ID (sha256 hash of subscriptionAuth)
        let sub: String
        /// Dapp domain url
        let app: String
        /// Message object
        let msg: NotifyMessage
    }

    struct Wrapper: JWTWrapper {
        let messageAuth: String

        init(jwtString: String) {
            self.messageAuth = jwtString
        }

        var jwtString: String {
            return messageAuth
        }
    }

    static var act: String {
        return "notify_message"
    }

    let castServerPubKey: DIDKey
    let keyserver: URL
    let account: Account
    let subscriptionId: String
    let app: String
    let message: NotifyMessage

    init(
        castServerPubKey: DIDKey,
        keyserver: URL,
        account: Account,
        subscriptionId: String,
        app: String,
        message: NotifyMessage
    ) {
        self.castServerPubKey = castServerPubKey
        self.keyserver = keyserver
        self.account = account
        self.subscriptionId = subscriptionId
        self.app = app
        self.message = message
    }

    init(claims: Claims) throws {
        self.castServerPubKey = try DIDKey(did: claims.iss)
        self.keyserver = try claims.ksu.asURL()
        self.account = try DIDPKH(did: claims.aud).account
        self.subscriptionId = claims.sub
        self.app = claims.app
        self.message = claims.msg
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1),
            ksu: keyserver.absoluteString,
            act: Self.act,
            iss: castServerPubKey.multibase(variant: .ED25519),
            aud: account.did,
            sub: subscriptionId,
            app: app,
            msg: message
        )
    }

}
