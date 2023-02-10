import Foundation

struct JWT<JWTClaims: JWTEncodable>: Codable, Equatable {
    enum Errors: Error {
        case jwtNotSigned
        case notUTF8String
        case notBase64Data
    }

    var header: JWTHeader
    var claims: JWTClaims
    var signature: String?

    init(header: JWTHeader = JWTHeader(), claims: JWTClaims) {
        self.header = header
        self.claims = claims
    }

    init(string: String) throws {
        guard let base64 = string.data(using: .utf8) else { throw Errors.notUTF8String }
        guard let data = Data(base64Encoded: base64) else { throw Errors.notBase64Data }
        self = try JSONDecoder().decode(JWT.self, from: data)
    }

    mutating func sign(using jwtSigner: JWTSigning) throws {
        header.alg = jwtSigner.alg
        let headerString = try header.encode()
        let claimsString = try claims.encode()
        self.signature = try jwtSigner.sign(header: headerString, claims: claimsString)
    }

    func encoded() throws -> String {
        guard let signature = signature else { throw Errors.jwtNotSigned }
        let headerString = try header.encode()
        let claimsString = try claims.encode()
        return [headerString, claimsString, signature].joined(separator: ".")
    }
}
