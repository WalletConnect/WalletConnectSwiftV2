import Foundation

struct ReceiptPayload: JWTClaimsCodable {

    struct Claims: JWTClaims {
        let iss: String
        let iat: UInt64
        let exp: UInt64
        let ksu: String

        let sub: String // hash of the message received
        let aud: String // sender blockchain account (did:pkh)
    }

    struct Wrapper: JWTWrapper {
        let receiptAuth: String

        init(jwtString: String) {
            self.receiptAuth = jwtString
        }

        var jwtString: String {
            return receiptAuth
        }
    }

    let keyserver: URL
    let messageHash: String
    let senderAccount: Account

    init(keyserver: URL, messageHash: String, senderAccount: Account) {
        self.keyserver = keyserver
        self.messageHash = messageHash
        self.senderAccount = senderAccount
    }

    init(claims: Claims) throws {
        self.keyserver = try claims.ksu.asURL()
        self.messageHash = claims.sub
        self.senderAccount = try Account(DIDPKHString: claims.aud)
    }

    func encode(iss: String) throws -> Claims {
        return Claims(
            iss: iss,
            iat: defaultIatMilliseconds(),
            exp: expiry(days: 30),
            ksu: keyserver.absoluteString,
            sub: messageHash,
            aud: DIDPKH(account: senderAccount).string
        )
    }
}
