import Foundation
@testable import KMS

extension AgreementSecret {
    
    static func stub() -> AgreementSecret {
        AgreementSecret(sharedSecret: Data.randomBytes(32), publicKey: AgreementPrivateKey().publicKey)
    }
}
