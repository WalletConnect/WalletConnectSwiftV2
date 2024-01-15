import Foundation

struct NotifyGetNotificationsRequestPayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        let iat: UInt64
        let exp: UInt64
        let sub: String
        let act: String?  // - `notify_get_notifications`
        let iss: String   // - did:key of client identity key
        let ksu: String   // - key server for identity key verification
        let aud: String   // - did:key of dapp authentication key
        let app: String   // - did:web of app domain that this request is associated with - Example: `did:web:app.example.com`
        let lmt: UInt64   // - the max number of notifications to return. Maximum value is 50.
        let aft: String?  // - the notification ID to start returning messages after. Null to start with the most recent notification
        let urf: Bool

        static var action: String? {
            return "notify_get_notifications"
        }
    }

    struct Wrapper: JWTWrapper {
        let auth: String

        init(jwtString: String) {
            self.auth = jwtString
        }

        var jwtString: String {
            return auth
        }
    }

    let account: Account
    let keyserver: String
    let dappAuthKey: DIDKey
    let app: DIDWeb
    let limit: UInt64
    let after: String?

    init(account: Account, keyserver: String, dappAuthKey: DIDKey, app: DIDWeb, limit: UInt64, after: String? = nil) {
        self.account = account
        self.keyserver = keyserver
        self.dappAuthKey = dappAuthKey
        self.app = app
        self.limit = limit
        self.after = after
    }

    init(claims: Claims) throws {
        fatalError()
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iat: defaultIat(),
            exp: expiry(days: 1), 
            sub: account.did,
            act: Claims.action,
            iss: iss,
            ksu: keyserver,
            aud: dappAuthKey.did(variant: .ED25519),
            app: app.did,
            lmt: limit,
            aft: after,
            urf: false
        )
    }
}
