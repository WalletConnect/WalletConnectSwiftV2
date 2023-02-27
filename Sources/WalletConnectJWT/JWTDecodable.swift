import Foundation

public protocol JWTWrapper: Codable {
    var jwtString: String { get }

    init(jwtString: String)
}

public protocol JWTClaims: JWTEncodable {
    var iss: String { get }
    var iat: Int64 { get }
    var exp: Int64 { get }
}

public protocol JWTClaimsCodable {
    associatedtype Claims: JWTClaims
    associatedtype Wrapper: JWTWrapper

    init(claims: Claims) throws

    func encode(iss: String) throws -> Claims
}

extension JWTClaimsCodable {

    public static func decode(from wrapper: Wrapper) throws -> (Self, Claims) {
        let jwt = try JWT<Claims>(string: wrapper.jwtString)

        let publicKey = try DIDKey(did: jwt.claims.iss)
        let signingPublicKey = try SigningPublicKey(rawRepresentation: publicKey.rawData)

        guard try jwt.isValid(publicKey: signingPublicKey) else {
            throw JWTError.signatureVerificationFailed
        }

        return (try Self.init(claims: jwt.claims), jwt.claims)
    }

    public func signAndCreateWrapper(keyPair: SigningPrivateKey) throws -> Wrapper {
        let claims = try encode(iss: keyPair.publicKey.did)
        var jwt = JWT(claims: claims)
        try jwt.sign(using: EdDSASigner(keyPair))
        let jwtString = try jwt.encoded()
        return Wrapper(jwtString: jwtString)
    }

    public func defaultIat() -> Int64 {
        return Int64(Date().timeIntervalSince1970)
    }

    public func defaultIatMilliseconds() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    public func expiry(days: Int) -> Int64 {
        var components = DateComponents()
        components.setValue(days, for: .day)
        let date = Calendar.current.date(byAdding: components, to: Date())!
        return Int64(date.timeIntervalSince1970)
    }
}
