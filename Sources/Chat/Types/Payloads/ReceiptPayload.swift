import Foundation

struct ReceiptPayload: Codable {
    let receiptAuth: String

    func decode() throws  -> (
        message: String,
        recipientAccount: Account,
        timestamp: Int
    ) {
        let claims = try JWTClaimsDecoder.claims(of: ChatMessageClaims.self, from: receiptAuth)
        return (
            message: claims.sub,
            recipientAccount: try Account(DIDPKHString: claims.aud),
            timestamp: claims.iat
        )
    }
}
