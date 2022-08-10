import Foundation

struct AuthPayload: Codable, Equatable {
    let domain: String
    let aud: String
    let version: Int
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
        self.version = 1
        self.nonce = requestParams.nonce
        self.iat = iat
        self.nbf = requestParams.nbf
        self.exp = requestParams.exp
        self.statement = requestParams.statement
        self.requestId = requestParams.requestId
        self.resources = requestParams.resources
    }

    init(payload: CacaoPayload) {
        self.type = "eip4361"
        self.chainId = "1" // TODO: Check this!
        self.domain = payload.domain
        self.aud = payload.aud
        self.version = payload.version
        self.nonce = payload.nonce
        self.iat = payload.iat
        self.nbf = payload.nbf
        self.exp = payload.exp
        self.statement = payload.statement
        self.requestId = payload.requestId
        self.resources = payload.resources
    }
}
