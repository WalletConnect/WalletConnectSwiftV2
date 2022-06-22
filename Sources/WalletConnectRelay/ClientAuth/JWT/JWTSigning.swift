import Foundation
import WalletConnectKMS

protocol JWTSigning {
    var alg: String {get}
    func sign(header: String, claims: String) throws -> String
}

struct EdDSASigner: JWTSigning {
    var alg = "EdDSA"
    let keys: SigningPrivateKey

    init(_ keys: SigningPrivateKey) {
        self.keys = keys
    }
    func sign(header: String, claims: String) throws  -> String {
        fatalError("not implemented")
    }
}
