import Foundation

struct InvitePayload: Codable {
    let inviteAuth: String

    func decode() throws -> (
        iss: String,
        message: String,
        account: Account,
        publicKey: String
    ) {
        let claims = try JWTClaimsDecoder.claims(of: ChatInviteProposalClaims.self, from: inviteAuth)
        let message = claims.sub
        let account = try Account(DIDPKHString: claims.aud)
        let publicKey = try DIDKey(did: claims.pke).hexString
        return (iss: claims.iss, message: message, account: account, publicKey: publicKey)
    }
}
