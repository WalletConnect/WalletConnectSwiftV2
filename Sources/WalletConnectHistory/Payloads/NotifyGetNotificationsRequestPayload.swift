import Foundation

struct NotifyGetNotificationsRequestPayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        var iss: String
        
        var iat: UInt64
        
        var exp: UInt64
        
        var act: String?

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

    init(claims: Claims) throws {
        fatalError()
    }

    func encode(iss: String) throws -> Claims {
        fatalError()
    }
}
