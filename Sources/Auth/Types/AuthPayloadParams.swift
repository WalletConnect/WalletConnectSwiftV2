import Foundation

struct AuthPayloadParams {
    let type: String
    let chainId: String
    let domain: String
    let aud: String
    let version: String
    let nonce: String
    let iat: String
    let nbf: String?
    let exp: String?
    let statement: String?
    let requestId: String?
    let resources: String?
}
