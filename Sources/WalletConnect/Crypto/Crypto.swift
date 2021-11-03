// 

import Foundation
import CryptoKit

class Crypto {
    
    private var keychain: KeychainStorageProtocol
    
    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }
    
    func set(privateKey: X25519.PrivateKey) {
        do {
            try keychain.add(privateKey.raw, forKey: privateKey.publicKey.toHexString())
        } catch {
            print("Error adding private key: \(error)")
        }
    }
    
    func set(agreementKeys: Crypto.X25519.AgreementKeys, topic: String) {
        let agreement = agreementKeys.sharedSecret + agreementKeys.publicKey
        do {
            try keychain.add(agreement, forKey: topic)
        } catch {
            print("Error adding agreement keys: \(error)")
        }
    }
    
    func getPrivateKey(for publicKey: Data) throws -> Crypto.X25519.PrivateKey? {
        guard let privateKeyData = try? keychain.read(key: publicKey.toHexString()) as Data else {
            return nil
        }
        return try Crypto.X25519.PrivateKey(raw: privateKeyData)
    }
    
    func getAgreementKeys(for topic: String) -> Crypto.X25519.AgreementKeys? {
        guard let agreement = try? keychain.read(key: topic) as Data else {
            return nil
        }
        let (sharedSecret, publicKey) = split(concatinatedAgreementKeys: agreement)
        return Crypto.X25519.AgreementKeys(sharedSecret: sharedSecret, publicKey: publicKey)
    }
    
    private func split(concatinatedAgreementKeys: Data) -> (Data, Data) {
        let sharedSecret = concatinatedAgreementKeys.subdata(in: 0..<32)
        let publicKey = concatinatedAgreementKeys.subdata(in: 32..<64)
        return (sharedSecret, publicKey)
    }
}
