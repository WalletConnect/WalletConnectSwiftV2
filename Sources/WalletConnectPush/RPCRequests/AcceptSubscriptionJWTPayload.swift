import Foundation

struct AcceptSubscriptionJWTPayload: JWTClaimsCodable {

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

    init(keyserver: URL, subscriptionAccount: Account, dappUrl: String) {
        self.keyserver = keyserver
        self.subscriptionAccount = subscriptionAccount
        self.dappUrl = dappUrl
    }

    init(claims: Claims) throws {
        self.keyserver = try claims.ksu.asURL()
        self.subscriptionAccount = try Account(DIDPKHString: claims.sub)
        self.dappUrl = claims.aud
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: expiry(days: 1),
            exp: defaultIatMilliseconds(),
            iss: iss,
            ksu: keyserver.absoluteString,
            aud: dappUrl,
            sub: subscriptionAccount.did
        )
    }
}
