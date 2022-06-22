import Foundation

protocol JWTSigning {
    var alg: String {get}
    func sign(header: String, claims: String) throws
}

struct EdDSASigner: JWTSigning {
    var alg = "EdDSA"
    func sign(header: String, claims: String) throws {

    }
}
