import Foundation

struct JWT<JWTClaims: JWTEncodable>: Codable, Equatable {
    enum Errors: Error {
        case jwtNotSigned
    }

    var header: JWTHeader
    var claims: JWTClaims
    var signature: String?

    init(header: JWTHeader = JWTHeader(), claims: JWTClaims) {
        self.header = header
        self.claims = claims
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
