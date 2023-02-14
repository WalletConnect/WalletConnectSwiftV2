import Foundation

public struct CacaoPayload: Codable, Equatable {
    public let iss: String
    public let domain: String
    public let aud: String
    public let version: String
    public let nonce: String
    public let iat: String
    public let nbf: String?
    public let exp: String?
    public let statement: String?
    public let requestId: String?
    public let resources: [String]?

    public init(
        iss: String,
        domain: String,
        aud: String,
        version: String,
        nonce: String,
        iat: String,
        nbf: String?,
        exp: String?,
        statement: String?,
        requestId: String?,
        resources: [String]?
    ) {
        self.iss = iss
        self.domain = domain
        self.aud = aud
        self.version = version
        self.nonce = nonce
        self.iat = iat
        self.nbf = nbf
        self.exp = exp
        self.statement = statement
        self.requestId = requestId
        self.resources = resources
    }
}
