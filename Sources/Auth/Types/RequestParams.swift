import Foundation

struct RequestParams {
    let domain: String
    let chainId: String
    let nonce: String
    let aud: String
    let nbf: String?
    let exp: String?
    let statement: String?
    let requestId: String?
    let resources: String?
}
