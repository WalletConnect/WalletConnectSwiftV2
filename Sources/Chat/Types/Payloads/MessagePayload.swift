import Foundation

struct MessagePayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        let iss: String
        let iat: UInt64
        let exp: UInt64
        let ksu: String

        let aud: String // recipient blockchain account (did:pkh)
        let sub: String // message sent by the author account
        let act: String? // description of action intent
        
        // TODO: Media not implemented
        // public let xma: Media?

        static var action: String? {
            return "chat_message"
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

    let keyserver: URL
    let message: String
    let recipientAccount: Account

    init(keyserver: URL, message: String, recipientAccount: Account) {
        self.keyserver = keyserver
        self.message = message
        self.recipientAccount = recipientAccount
    }

    init(claims: Claims) throws {
        self.keyserver = try claims.ksu.asURL()
        self.message = claims.sub
        self.recipientAccount = try Account(DIDPKHString: claims.aud)
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iss: iss,
            iat: defaultIatMilliseconds(),
            exp: expiry(days: 30),
            ksu: keyserver.absoluteString,
            aud: recipientAccount.did,
            sub: message,
            act: Claims.action
        )
    }
}
