import Foundation

protocol IDAuthClaims: JWTClaims {
    var iss: String { get }
    var sub: String { get }
    var aud: String { get }
    var iat: UInt64 { get }
    var exp: UInt64 { get }
    var pkh: String { get }
    var act: String? { get }

    init(iss: String, sub: String, aud: String, iat: UInt64, exp: UInt64, pkh: String, act: String?)
}
