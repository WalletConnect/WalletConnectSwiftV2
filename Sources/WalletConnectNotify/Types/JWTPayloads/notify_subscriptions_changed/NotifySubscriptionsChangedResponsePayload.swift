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

        static var action: String? {
            return "notify_watch_subscriptions"
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

    init(keyserver: URL) {
        self.keyserver = keyserver
    }

    let selfIdentityKey: DIDKey
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
            aud: selfIdentityKey.did(variant: .ED25519)
        )
    }

}

