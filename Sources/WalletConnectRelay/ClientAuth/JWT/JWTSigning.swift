import Foundation
import WalletConnectKMS

protocol JWTSigning {
    var alg: String {get}
    func sign(header: String, claims: String) throws -> String
}

struct EdDSASigner: JWTSigning {
    var alg = "EdDSA"
    let privateKey: SigningPrivateKey

    init(_ keys: SigningPrivateKey) {
        self.privateKey = keys
    }
    func sign(header: String, claims: String) throws  -> String {
        try privateKey.signature(for: <#T##Data#>)
    }
}
