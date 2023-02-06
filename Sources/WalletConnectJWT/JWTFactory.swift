import Foundation

public struct JWTFactory {

    public init() { }

    public func createAndSignJWT(
        keyPair: SigningPrivateKey,
        aud: String,
        exp: Int,
        pkh: String?
    ) throws -> String {
        let now = Int(Date().timeIntervalSince1970)
        let iss = keyPair.DIDKey
        let sub = generateSubject()
        let claims = JWT.Claims(iss: iss, sub: sub, aud: aud, iat: now, exp: exp, pkh: pkh)
        var jwt = JWT(claims: claims)
        try jwt.sign(using: EdDSASigner(keyPair))
        return try jwt.encoded()
    }
}

private extension JWTFactory {

    private func generateSubject() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }
}
