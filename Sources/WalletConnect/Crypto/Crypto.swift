// 

import Foundation
import CryptoKit

// TODO: Come up with better naming conventions
protocol CryptoStorageProtocol {
    func makePrivateKey() -> Curve25519.KeyAgreement.PrivateKey
    func set(privateKey: Curve25519.KeyAgreement.PrivateKey) throws
    func getPrivateKey(for publicKey: Curve25519.KeyAgreement.PublicKey) throws -> Curve25519.KeyAgreement.PrivateKey?
    
    func generatePrivateKey() -> Crypto.X25519.PrivateKey
    func set(privateKey: Crypto.X25519.PrivateKey)
    func set(agreementKeys: Crypto.X25519.AgreementKeys, topic: String)
    func getPrivateKey(for publicKey: Data) throws -> Crypto.X25519.PrivateKey?
    func getAgreementKeys(for topic: String) -> Crypto.X25519.AgreementKeys?
    func deletePrivateKey(for publicKey: String)
    func deleteAgreementKeys(for topic: String)
}

class Crypto: CryptoStorageProtocol {
    
    private var keychain: KeychainStorageProtocol
    
    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }
    
    func set(privateKey: Curve25519.KeyAgreement.PrivateKey) throws {
        try keychain.add(privateKey.rawRepresentation, forKey: privateKey.publicKey.rawRepresentation.toHexString())
    }

    func getPrivateKey(for publicKey: Curve25519.KeyAgreement.PublicKey) throws -> Curve25519.KeyAgreement.PrivateKey? {
        guard let privateKeyData = try? keychain.read(key: publicKey.rawRepresentation.toHexString()) as Data else {
            return nil
        }
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData)
    }
    
    // -------
    func makePrivateKey() -> Curve25519.KeyAgreement.PrivateKey {
        Curve25519.KeyAgreement.PrivateKey() // TODO: Store private key when creating
    }
    
    func generatePrivateKey() -> Crypto.X25519.PrivateKey {
        Crypto.X25519.PrivateKey()
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
    
    func deletePrivateKey(for publicKey: String) {
        do {
            try keychain.delete(key: publicKey)
        } catch {
            print("Error deleting private key: \(error)")
        }
    }
    
    func deleteAgreementKeys(for topic: String) {
        do {
            try keychain.delete(key: topic)
        } catch {
            print("Error deleting agreement key: \(error)")
        }
    }
    
    private func split(concatinatedAgreementKeys: Data) -> (Data, Data) {
        let sharedSecret = concatinatedAgreementKeys.subdata(in: 0..<32)
        let publicKey = concatinatedAgreementKeys.subdata(in: 32..<64)
        return (sharedSecret, publicKey)
    }
}



extension Crypto.X25519 {
    struct PrivateKey: Equatable {
        let privateKey: Curve25519.KeyAgreement.PrivateKey
        
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



extension Crypto {
    
    static func generateAgreementKeys(peerPublicKey: Data, privateKey: Curve25519.KeyAgreement.PrivateKey, sharedInfo: Data = Data()) throws -> Crypto.X25519.AgreementKeys {
//        let cryptoKitPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey.raw)
        let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKey)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let rawSharedSecret = sharedSecret.withUnsafeBytes { return Data(Array($0)) }
        return Crypto.X25519.AgreementKeys(sharedSecret: rawSharedSecret, publicKey: privateKey.publicKey.rawRepresentation)
    }
    
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
