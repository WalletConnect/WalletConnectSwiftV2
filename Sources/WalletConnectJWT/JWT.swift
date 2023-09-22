import Foundation

struct JWT<JWTClaims: JWTEncodable>: Codable, Equatable {

    let header: JWTHeader
    let claims: JWTClaims
    let signature: String
    let string: String

    init(claims: JWTClaims, signer: JWTSigning) throws {
        self.header = JWTHeader(alg: signer.alg)
        self.claims = claims

        let headerString = try header.encode()
        let claimsString = try claims.encode()
        let signature = try signer.sign(header: headerString, claims: claimsString)
        
        self.signature = signature
        self.string = [headerString, claimsString, signature].joined(separator: ".")
    }

    init(string: String) throws {
        let components = string.components(separatedBy: ".")

        guard components.count == 3 else { throw JWTError.undefinedFormat }

        self.header = try JWTHeader.decode(from: components[0])
        self.claims = try JWTClaims.decode(from: components[1])
        self.signature = components[2]
        self.string = string
    }
}
