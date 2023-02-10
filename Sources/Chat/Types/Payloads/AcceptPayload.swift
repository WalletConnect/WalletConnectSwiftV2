import Foundation

struct AcceptPayload: Codable {
    let responseAuth: String

    func decode() throws -> (account: Account, publicKey: String) {
        let claims = try JWTClaimsDecoder.claims(of: ChatInviteApprovalClaims.self, from: responseAuth)
        let account = try Account(DIDPKHString: claims.aud)
        let publicKey = try DIDKey(did: claims.sub).hexString
        return (account: account, publicKey: publicKey)
    }
}
