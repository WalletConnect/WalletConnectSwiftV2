import Foundation

struct NotifyMessagePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        let iat: UInt64 // issued at
        let exp: UInt64 // expiry
        let iss: String // did:key of an identity key. Enables to resolve associated Dapp domain used. diddoc authentication key
        let ksu: String // key server url
        let aud: String // blockchain account (did:pkh)
        let act: String // action intent (must be "notify_message")
        let sub: String // subscriptionId (sha256 hash of subscriptionAuth)
        let app: String // dapp domain url,
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
            iss: castServerPubKey.multibase(variant: .ED25519),
            ksu: keyserver.absoluteString,
            aud: account.did,
            act: "notify_message",
            sub: subscriptionId,
            app: app,
            msg: message
        )
    }

}
