import Foundation
@testable import WalletConnectKMS

extension AgreementSecret {
    
    static func stub() -> AgreementSecret {
        AgreementSecret(sharedSecret: Data.randomBytes(count: 32), publicKey: AgreementPrivateKey().publicKey)
    }
}
