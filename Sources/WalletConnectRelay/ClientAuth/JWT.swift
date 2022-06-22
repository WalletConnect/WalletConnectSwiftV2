import Foundation

struct JWT {
    public var header: Header
    public var claims: Claims

    public init(header: Header = Header(), claims: Claims) {
        self.header = header
        self.claims = claims
    }

    public mutating func sign(using jwtSigner: JWTSigning) throws {
        var tempHeader = header
        tempHeader.alg = jwtSigner.alg
        let headerString = try tempHeader.encode()
        let claimsString = try claims.encode()
        header.alg = tempHeader.alg
        return try jwtSigner.sign(header: headerString, claims: claimsString)
    }

    func encoded() -> String {

    }
}

protocol JWTSigning {
    var alg: String {get}
    func sign(header: String, claims: String) throws
}

struct EdDSASigner: JWTSigning {
    var alg = "EdDSA"
    func sign(header: String, claims: String) throws {

    }
}

extension JWT {
    struct Header {
        var alg: String!
        let typ: String = "JWT"
    }
}

extension JWT {
    struct Claims {
        let iss: String
        let sub: String
    }
}
