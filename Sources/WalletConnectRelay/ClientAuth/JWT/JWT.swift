import Foundation

struct JWT: Codable, Equatable {
    enum Errors: Error {
        case jwtNotSigned
    }
    
    var header: Header
    var claims: Claims
    var signature: String? = nil

    public init(header: Header = Header(), claims: Claims) {
        self.header = header
        self.claims = claims
    }

    public mutating func sign(using jwtSigner: JWTSigning) throws {
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

extension JWT {
    struct Header: Codable, Equatable {
        var alg: String!
        let typ: String = "JWT"

        func encode() throws -> String  {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .secondsSince1970
            let data = try jsonEncoder.encode(self)
            return JWTEncoder.base64urlEncodedString(data: data)
        }
    }
}

extension JWT {
    struct Claims: Codable, Equatable {
        let iss: String
        let sub: String
        func encode() throws -> String  {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .secondsSince1970
            let data = try jsonEncoder.encode(self)
            return JWTEncoder.base64urlEncodedString(data: data)
        }
    }
}

