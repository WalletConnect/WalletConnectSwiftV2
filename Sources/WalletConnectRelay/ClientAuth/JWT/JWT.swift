import Foundation

struct JWT {
    public var header: Header
    public var claims: Claims
    var signature: Data? = nil

    public init(header: Header = Header(), claims: Claims) {
        self.header = header
        self.claims = claims
    }

    public mutating func sign(using jwtSigner: JWTSigning) throws {
        fatalError("not implemented")

//        var tempHeader = header
//        tempHeader.alg = jwtSigner.alg
//        let headerString = try tempHeader.encode()
//        let claimsString = try claims.encode()
//        header.alg = tempHeader.alg
//        return try jwtSigner.sign(header: headerString, claims: claimsString)
    }

    func encoded() -> String {
        fatalError("not implemented")

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
