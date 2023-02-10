import Foundation

struct MessagePayload: Codable {
    let messageAuth: String

    func decode() throws  -> (
        message: String,
        recipientAccount: Account,
        timestamp: Int
    ) {
        let claims = try JWTClaimsDecoder.claims(of: ChatMessageClaims.self, from: messageAuth)
        return (
            message: claims.sub,
            recipientAccount: try Account(DIDPKHString: claims.aud),
            timestamp: claims.iat
        )
    }
}
