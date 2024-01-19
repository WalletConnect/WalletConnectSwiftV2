import Foundation

struct NotifyGetNotificationsResponsePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        let iat: UInt64
        let exp: UInt64
        let act: String? // - `notify_get_notifications_response`
        let iss: String // - did:key of client identity key
        let aud: String // - did:key of Notify Server authentication key
        let nfs: [NotifyMessage] //  array of [Notify Notifications](./data-structures.md#notify-notification)

        static var action: String? {
            return "notify_get_notifications_response"
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

    let messages: [NotifyMessage]

    init(claims: Claims) throws {
        self.messages = claims.nfs
    }

    func encode(iss: String) throws -> Claims {
        fatalError()
    }
}
