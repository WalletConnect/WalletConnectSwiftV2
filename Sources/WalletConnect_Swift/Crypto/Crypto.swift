// 

import Foundation
import CryptoKit

class Crypto {
    private var keychain: Keychain
    
    init(keychain: Keychain = DictionaryKeychain()) {
        self.keychain = keychain
    }
    
    func set(privateKey: X25519.PrivateKey) {
        let key = privateKey.publicKey.toHexString()
        keychain[key] = privateKey.raw
    }
    
    func set(agreementKeys: Crypto.X25519.AgreementKeys, topic: String) {
        keychain[topic] = agreementKeys.sharedKey + agreementKeys.publicKey
    }
    
    func getPrivateKey(for publicKey: Data) throws -> Crypto.X25519.PrivateKey? {
        guard let privateKeyData = keychain[publicKey.toHexString()] else {
            return nil
        }
        return try Crypto.X25519.PrivateKey(raw: privateKeyData)
    }
    
    func getAgreementKeys(for topic: String) -> Crypto.X25519.AgreementKeys? {
        guard let concatenatedAgreementKeys = keychain[topic] else {
            return nil
        }
        let (sharedKey, publicKey) = split(concatinatedAgreementKeys: concatenatedAgreementKeys)
        return Crypto.X25519.AgreementKeys(sharedKey: sharedKey, publicKey: publicKey)
    }
    
    private func split(concatinatedAgreementKeys: Data) -> (Data, Data) {
        let sharedKey = concatinatedAgreementKeys.subdata(in: 0..<32)
        let publicKey = concatinatedAgreementKeys.subdata(in: 32..<64)
        return (sharedKey, publicKey)
    }
}

