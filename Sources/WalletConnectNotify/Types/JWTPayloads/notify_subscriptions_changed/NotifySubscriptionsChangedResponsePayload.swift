import Foundation

struct NotifySubscriptionsChangedResponsePayload: JWTClaimsCodable {
    struct Claims: JWTClaims {
        /// Timestamp when JWT was issued
        let iat: UInt64
        /// Timestamp when JWT must expire
        let exp: UInt64
        /// Key server URL
        let ksu: String
        /// Description of action intent. Must be equal to `notify_subscriptions_changed_response`
        let act: String?

        /// `did:key` of client identity key
        let iss: String
        /// `did:key` of Notify Server authentication key
        let aud: String
        /// Blockchain account that notify subscription has been proposed for -`did:pkh`
        let sub: String

        static var action: String? {
            return "notify_subscriptions_changed_response"
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

    init(account: Account, keyserver: URL, notifyServerAuthenticationKey: DIDKey) {
        self.account = account
        self.keyserver = keyserver
        self.notifyServerAuthenticationKey = notifyServerAuthenticationKey
    }

    let account: Account
    let notifyServerAuthenticationKey: DIDKey
    let keyserver: URL

    init(claims: Claims) throws {
        fatalError("Method not expected to be called by the client")
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 30),
            ksu: keyserver.absoluteString,
            act: Claims.action,
            iss: iss,
            aud: notifyServerAuthenticationKey.did(variant: .ED25519),
            sub: account.did
        )
    }

}

