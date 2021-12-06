// 

import Foundation
import CryptoKit

extension Crypto.X25519 {
    struct PrivateKey: Equatable {
        private let privateKey: Curve25519.KeyAgreement.PrivateKey
        
        var raw: Data {
            return privateKey.rawRepresentation
        }
        var publicKey: Data {
            return privateKey.publicKey.rawRepresentation
        }
        
        init(){
            privateKey = Curve25519.KeyAgreement.PrivateKey()
        }
        
        init(raw: Data) throws {
            privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: raw)
        }
        
        static func == (lhs: Crypto.X25519.PrivateKey, rhs: Crypto.X25519.PrivateKey) -> Bool {
            lhs.raw == rhs.raw
        }
    }
    
    struct AgreementKeys: Equatable {
        let sharedSecret: Data
        let publicKey: Data
        
        func derivedTopic() -> String {
            sharedSecret.sha256().toHexString()
        }
    }
}
