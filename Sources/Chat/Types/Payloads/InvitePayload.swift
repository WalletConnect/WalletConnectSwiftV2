import Foundation

struct InvitePayload: Codable {
    let inviteAuth: String

    func decode() throws -> (message: String, account: Account, publicKey: String) {
        let claims = try JWTClaimsDecoder.claims(of: ChatInviteProposalClaims.self, from: inviteAuth)
        let message = claims.sub
        let account = try Account(DIDPKHString: claims.iss)
        let publicKey = try DIDKey(did: claims.pke).hexString
        return (message: message, account: account, publicKey: publicKey)
    }
}
