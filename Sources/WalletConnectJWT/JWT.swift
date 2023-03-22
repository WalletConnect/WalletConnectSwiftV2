import Foundation

struct JWT<JWTClaims: JWTEncodable>: Codable, Equatable {

    var header: JWTHeader
    var claims: JWTClaims
    var signature: String?

    init(header: JWTHeader = JWTHeader(), claims: JWTClaims) {
        self.header = header
        self.claims = claims
    }

    init(string: String) throws {
        let components = string.components(separatedBy: ".")

        guard components.count == 3 else { throw JWTError.undefinedFormat }

        self.header = try JWTHeader.decode(from: components[0])
        self.claims = try JWTClaims.decode(from: components[1])
        self.signature = components[2]
    }

    mutating func sign(using jwtSigner: JWTSigning) throws {
        header.alg = jwtSigner.alg
        let headerString = try header.encode()
        let claimsString = try claims.encode()
        self.signature = try jwtSigner.sign(header: headerString, claims: claimsString)
    }

    func isValid(publicKey: SigningPublicKey) throws -> Bool {
        guard let signature else { throw JWTError.noSignature }

        let headerString = try header.encode()
        let claimsString = try claims.encode()
        let unsignedJWT = [headerString, claimsString].joined(separator: ".")

        guard let unsignedData = unsignedJWT.data(using: .utf8) else {
            throw JWTError.invalidJWTString
        }

        let signatureData = try JWTEncoder.base64urlDecodedData(string: signature)
        return publicKey.isValid(signature: signatureData, for: unsignedData)
    }

    func encoded() throws -> String {
        guard let signature = signature else { throw JWTError.jwtNotSigned }
        let headerString = try header.encode()
        let claimsString = try claims.encode()
        return [headerString, claimsString, signature].joined(separator: ".")
    }
}
