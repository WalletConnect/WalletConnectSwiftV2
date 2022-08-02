import Foundation

struct CacaoPayload: Codable, Equatable {
    let iss: String
    let domain: String
    let aud: String
    let version: String
    let nonce: String
    let iat: String
    let nbf: String
    let exp: String
    let statement: String
    let requestId: String
    let resources: String
}
