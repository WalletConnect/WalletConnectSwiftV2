import Foundation

// TODO: Remove
public struct JWTClaimsDecoder {

    public static func claims<Claims: JWTEncodable>(
        of type: Claims.Type,
        from jwtString: String
    ) throws -> Claims {
        let jwt = try JWT<Claims>(string: jwtString)
        return jwt.claims
    }
}

public protocol JWTWrapper: Codable {
    var jwtString: String { get }

    init(jwtString: String)
}

public protocol JWTClaimsCodable {
    associatedtype Claims: JWTEncodable
    associatedtype Wrapper: JWTWrapper

    init(claims: Claims) throws

    func encode(iss: String) throws -> Claims
}

extension JWTClaimsCodable {

    public static func decode(from wrapper: Wrapper) throws -> (Self, Claims) {
        let jwt = try JWT<Claims>(string: wrapper.jwtString)
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
