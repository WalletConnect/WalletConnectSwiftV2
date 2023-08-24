import Foundation

struct UnregisterIdentityClaims: IDAuthClaims {
    let iss: String
    let sub: String
    let aud: String
    let iat: UInt64
    let exp: UInt64
    let pkh: String
    let act: String?

    static var action: String? {
        return "unregister_identity"
    }
}
