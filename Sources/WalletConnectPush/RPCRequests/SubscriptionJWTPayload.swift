import Foundation

struct SubscriptionJWTPayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        /// timestamp when jwt was issued
        let iat: UInt64
        /// timestamp when jwt must expire
        let exp: UInt64
        /// did:key of an identity key. Enables to resolve attached blockchain account.
        let iss: String
        /// key server for identity key verification
        let ksu: String
        /// dapp's url
        let aud: String
        /// blockchain account that push subscription has been proposed for (did:pkh)
        let sub: String
        /// description of action intent. Must be equal to "push_subscription"
        let act: String

        let scp: String
    }

    struct Wrapper: JWTWrapper {
        let subscriptionAuth: String

        init(jwtString: String) {
            self.subscriptionAuth = jwtString
        }

        var jwtString: String {
            return subscriptionAuth
        }
    }

    let keyserver: URL
    let subscriptionAccount: Account
    let dappUrl: String
    let scope: String

    init(keyserver: URL, subscriptionAccount: Account, dappUrl: String, scope: String) {
        self.keyserver = keyserver
        self.subscriptionAccount = subscriptionAccount
        self.dappUrl = dappUrl
        self.scope = scope
    }

    init(claims: Claims) throws {
        self.keyserver = try claims.ksu.asURL()
        self.subscriptionAccount = try Account(DIDPKHString: claims.sub)
        self.dappUrl = claims.aud
        self.scope = claims.scp
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIatMilliseconds(),
            exp: expiry(days: 30),
            iss: iss,
            ksu: keyserver.absoluteString,
            aud: dappUrl,
            sub: subscriptionAccount.did,
            act: "push_subscription",
            scp: scope
        )
    }
}

