import Foundation

public struct RequestParams {
    public let domain: String
    public let chainId: String
    public let nonce: String
    public let aud: String
    public let nbf: String?
    public let exp: String?
    public let statement: String?
    public let requestId: String?
    public let resources: [String]?

    public init(
        domain: String,
        chainId: String,
        nonce: String,
        aud: String,
        nbf: String?,
        exp: String?,
        statement: String?,
        requestId: String?,
        resources: [String]?
    ) {
        self.domain = domain
        self.chainId = chainId
        self.nonce = nonce
        self.aud = aud
        self.nbf = nbf
        self.exp = exp
        self.statement = statement
        self.requestId = requestId
        self.resources = resources
    }
}
