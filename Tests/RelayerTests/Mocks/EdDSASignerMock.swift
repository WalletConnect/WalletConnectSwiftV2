import Foundation
@testable import WalletConnectJWT
@testable import WalletConnectRelay

class EdDSASignerMock: JWTSigning {
    var alg: String = "EdDSA"
    var signature: String!

    func sign(header: String, claims: String) throws -> String {
        return signature
    }
}
