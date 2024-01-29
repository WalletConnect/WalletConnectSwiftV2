import Foundation

struct NotifyUpdateResponsePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// timestamp when jwt was issued
        let iat: UInt64
        /// timestamp when jwt must expire
        let exp: UInt64
        /// Description of action intent. Must be equal to "notify_update_response"
        let act: String?

        /// `did:key` of an identity key. Enables to resolve associated Dapp domain used.
        let iss: String
        /// `did:key` of an identity key. Enables to resolve attached blockchain account.
        let aud: String
        /// Blockchain account that notify subscription has been proposed for -`did:pkh`
        let sub: String
        /// array of Notify Server Subscriptions
        let sbs: [NotifyServerSubscription]
        /// Dapp's domain url
        let app: String

        static var action: String? {
            return "notify_update_response"
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
    let subscriptions: [NotifyServerSubscription]

    init(claims: Claims) throws {
        self.account = try Account(DIDPKHString: claims.sub)
        self.selfPubKey = try DIDKey(did: claims.aud)
        self.app = try DIDWeb(did: claims.app)
        self.subscriptions = claims.sbs
    }

    func encode(iss: String) throws -> Claims {
        fatalError()
    }
}
