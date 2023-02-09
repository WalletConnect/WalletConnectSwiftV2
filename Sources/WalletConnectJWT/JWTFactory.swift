import Foundation

public struct JWTFactory {

    public init() { }

    public func createRelayJWT(
        keyPair: SigningPrivateKey,
        sub: String,
        aud: String,
        exp: Int
    ) throws -> String {
        let now = Int(Date().timeIntervalSince1970)
        let iss = keyPair.DIDKey
        let claims = RelayClaims(iss: iss, sub: sub, aud: aud, iat: now, exp: exp)
        return try createAndSignJWT(keyPair: keyPair, claims: claims)
    }

    public func createChatInviteJWT(
        keyPair: SigningPrivateKey,
        sub: String,
        aud: String,
        exp: Int,
        pkh: String
    ) throws -> String {
        let iss = keyPair.DIDKey
        let claims = ChatInviteClaims(iss: iss, sub: sub, aud: aud, iat: getIat(), exp: exp, phk: pkh)
        return try createAndSignJWT(keyPair: keyPair, claims: claims)
    }
}

private extension JWTFactory {

    func createAndSignJWT<JWTClaims: JWTEncodable>(
        keyPair: SigningPrivateKey,
        claims: JWTClaims
    ) throws -> String {
        var jwt = JWT(claims: claims)
        try jwt.sign(using: EdDSASigner(keyPair))
        return try jwt.encoded()
    }

    func getIat() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
}
