import Foundation

struct NotifyMessagePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Action intent (must be `notify_message`)
        let act: String?

        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used. diddoc authentication key
        let iss: String
        /// Blockchain account that notify subscription has been proposed for -`did:pkh`
        let sub: String
        /// Dapp domain url
        let app: String
        /// Message object
        let msg: NotifyMessage

        static var action: String? {
            return "notify_message"
        }
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

    let dappAuthenticationKey: DIDKey
    let account: Account
    let app: DIDWeb
    let message: NotifyMessage

    init(claims: Claims) throws {
        self.dappAuthenticationKey = try DIDKey(did: claims.iss)
        self.account = try DIDPKH(did: claims.sub).account
        self.app = try DIDWeb(did: claims.app)
        self.message = claims.msg
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1),
            act: Claims.action,
            iss: dappAuthenticationKey.multibase(variant: .ED25519),
            sub: account.did,
            app: app.did,
            msg: message
        )
    }

}
