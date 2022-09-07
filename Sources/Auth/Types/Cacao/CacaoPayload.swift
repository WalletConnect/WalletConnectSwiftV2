import Foundation

struct CacaoPayload: Codable, Equatable {
    let iss: String
    let domain: String
    let aud: String
    let version: String
    let nonce: String
    let iat: String
    let nbf: String?
    let exp: String?
    let statement: String?
    let requestId: String?
    let resources: [String]?

    init(params: AuthPayload, didpkh: DIDPKH) {
        self.iss = didpkh.iss
        self.domain = params.domain
        self.aud = params.aud
        self.version = "1"
        self.nonce = params.nonce
        self.iat = params.iat
        self.nbf = params.nbf
        self.exp = params.exp
        self.statement = params.statement
        self.requestId = params.requestId
        self.resources = params.resources
    }
}
