import Foundation

struct ReceiptPayload: Codable {
    let receiptAuth: String

    func decode() throws  -> (
        messageHash: String,
        senderAccount: Account,
        timestamp: Int64
    ) {
        let claims = try JWTClaimsDecoder.claims(of: ChatMessageClaims.self, from: receiptAuth)
        return (
            messageHash: claims.sub,
            senderAccount: try Account(DIDPKHString: claims.aud),
            timestamp: claims.iat
        )
    }
}
