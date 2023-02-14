import Foundation

struct MessagePayload: Codable {
    let messageAuth: String

    func decode() throws  -> (
        iss: String,
        message: String,
        recipientAccount: Account,
        timestamp: Int64
    ) {
        let claims = try JWTClaimsDecoder.claims(of: ChatMessageClaims.self, from: messageAuth)
        return (
            iss: claims.iss,
            message: claims.sub,
            recipientAccount: try Account(DIDPKHString: claims.aud),
            timestamp: claims.iat
        )
    }
}
