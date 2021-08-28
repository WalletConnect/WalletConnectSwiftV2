// 

import Foundation
import CryptoKit
class Crypto {
    class X25519 {
        static func getSharedSecretKey(from connectionPublicKeyData: Data, clientPrivateKey: Curve25519.KeyAgreement.PrivateKey, sharedInfo: Data) -> SymmetricKey {
            let connectionPublicKey = try! Curve25519.KeyAgreement.PublicKey(rawRepresentation: connectionPublicKeyData)
            let sharedSecret = try! clientPrivateKey.sharedSecretFromKeyAgreement(with: connectionPublicKey)
            let sharedSecretyKey = sharedSecret.x963DerivedSymmetricKey(using: SHA256.self, sharedInfo: Data(), outputByteCount: 32)
            return sharedSecretyKey
        }
    }
}
