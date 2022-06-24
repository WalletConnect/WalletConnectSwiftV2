import Foundation
import WalletConnectKMS

protocol JWTSigning {
    var alg: String {get}
    func sign(header: String, claims: String) throws -> String
}

struct EdDSASigner: JWTSigning {
    enum Errors: Error {
        case invalidJWTString
    }
    var alg = "EdDSA"
    let privateKey: SigningPrivateKey

    init(_ keys: SigningPrivateKey) {
        self.privateKey = keys
    }

    func sign(header: String, claims: String) throws  -> String {
        let unsignedJWT = header + "." + claims
        guard let unsignedData = unsignedJWT.data(using: .utf8) else {
            throw Errors.invalidJWTString
        }
        let signature = try privateKey.signature(unsignedData)
        let signatureString = JWTEncoder.base64urlEncodedString(data: signature)
        return signatureString
    }
}
