import Foundation
@testable import WalletConnectRelay

class EdDSASignerMock: JWTSigning {
    var alg: String = "EdDSA"

    func sign(header: String, claims: String) throws -> String {
        return signature
    }

    var signature: String!
}
