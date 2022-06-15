import Foundation
@testable import WalletConnectKMS

extension AgreementKeys {

    static func stub() -> AgreementKeys {
        let key = try! SymmetricKey(rawRepresentation: Data.randomBytes(count: 32))
        return AgreementKeys(sharedKey: key, publicKey: AgreementPrivateKey().publicKey)
    }
}
