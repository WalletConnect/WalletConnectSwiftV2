import Foundation

public struct AuthenticationPayload: Codable, Equatable {
    public let domain: String
    public let aud: String
    public let version: String
    public let nonce: String
    public let chains: [String]
    public let type: String
    public let iat: String
    public let nbf: String?
    public let exp: String?
    public let statement: String?
    public let requestId: String?
    public let resources: [String]?

    init(requestParams: RequestParams, iat: String) {
        self.type = "eip4361"
        self.chains = requestParams.chains
        self.domain = requestParams.domain
        self.aud = requestParams.aud
        self.version = "1"
        self.nonce = requestParams.nonce
        self.iat = iat
        self.nbf = requestParams.nbf
        self.exp = requestParams.exp
        self.statement = requestParams.statement
        self.requestId = requestParams.requestId
        self.resources = requestParams.resources
    }

    func cacaoPayload(account: Account) throws -> CacaoPayload {
        return CacaoPayload(
            iss: account.did,
            domain: domain,
            aud: aud,
            version: version,
            nonce: nonce,
            iat: iat,
            nbf: nbf,
            exp: exp,
            statement: statement,
            requestId: requestId,
            resources: resources
        )
    }
}

