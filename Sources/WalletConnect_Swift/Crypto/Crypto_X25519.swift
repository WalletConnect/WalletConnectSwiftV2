// 

import Foundation
import CryptoKit

extension Crypto {
    enum X25519 {
        static func generatePrivateKey() -> Crypto.X25519.PrivateKey {
            Crypto.X25519.PrivateKey()
        }
        
        static func generateAgreementKeys(peerPublicKey: Data, privateKey: Crypto.X25519.PrivateKey, sharedInfo: Data = Data()) throws -> Crypto.X25519.AgreementKeys {
            let cryptoKitPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey.raw)
            let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKey)
            let sharedSecret = try cryptoKitPrivateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
            let sharedKey = sharedSecret.x963DerivedSymmetricKey(using: SHA256.self, sharedInfo: sharedInfo, outputByteCount: 32)
            let rawSharedKey = sharedKey.withUnsafeBytes { return Data(Array($0)) }
            return AgreementKeys(sharedKey: rawSharedKey, publicKey: privateKey.publicKey)
        }
    }
}
