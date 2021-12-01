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
            let rawSharedSecret = sharedSecret.withUnsafeBytes { return Data(Array($0)) }
            return AgreementKeys(sharedSecret: rawSharedSecret, publicKey: privateKey.publicKey)
        }
    }
}
