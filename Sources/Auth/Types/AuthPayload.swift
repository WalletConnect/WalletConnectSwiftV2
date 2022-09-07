import Foundation

struct AuthPayload: Codable, Equatable {
    let domain: String
    let aud: String
    let version: String
    let nonce: String
    let chainId: String
    let type: String
    let iat: String
    let nbf: String?
    let exp: String?
    let statement: String?
    let requestId: String?
    let resources: [String]?

    init(requestParams: RequestParams, iat: String) {
        self.type = "eip4361"
        self.chainId = requestParams.chainId
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
}
