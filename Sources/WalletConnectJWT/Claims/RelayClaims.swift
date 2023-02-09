import Foundation

struct RelayClaims: JWTEncodable {
    let iss: String
    let sub: String
    let aud: String
    let iat: Int
    let exp: Int
}
