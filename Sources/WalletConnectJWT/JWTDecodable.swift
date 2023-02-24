import Foundation

public struct JWTClaimsDecoder {

    public static func claims<Claims: JWTEncodable>(
        of type: Claims.Type,
        from jwtString: String
    ) throws -> Claims {
        let jwt = try JWT<Claims>(string: jwtString)
        return jwt.claims
    }
}
