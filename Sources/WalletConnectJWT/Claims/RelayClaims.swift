import Foundation

public struct RelayClaims: JWTEncodable {
    let iss: String
    let sub: String
    let aud: String
    let iat: Int64
    let exp: Int64
}
