// 

import Foundation
import CryptoKit

struct AgreementKeys: Equatable {
    let sharedSecret: Data
    let publicKey: Curve25519.KeyAgreement.PublicKey
    
    func derivedTopic() -> String {
        sharedSecret.sha256().toHexString()
    }
}

extension Curve25519.KeyAgreement.PublicKey {
    
    var hexRepresentation: String {
        rawRepresentation.toHexString()
    }
}

extension Curve25519.KeyAgreement.PublicKey: Equatable {
    
    public static func == (lhs: Curve25519.KeyAgreement.PublicKey, rhs: Curve25519.KeyAgreement.PublicKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

// TODO: Come up with better naming conventions
protocol CryptoStorageProtocol {
    func makePrivateKey() -> Curve25519.KeyAgreement.PrivateKey
    func set(privateKey: Curve25519.KeyAgreement.PrivateKey) throws
    func getPrivateKey(for publicKey: Curve25519.KeyAgreement.PublicKey) throws -> Curve25519.KeyAgreement.PrivateKey?
    func set(agreementKeys: AgreementKeys, topic: String) throws
    func getAgreementKeys(for topic: String) -> AgreementKeys?
    func deletePrivateKey(for publicKey: String)
    func deleteAgreementKeys(for topic: String)
}

class Crypto: CryptoStorageProtocol {
    
    private var keychain: KeychainStorageProtocol
    
    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }
    
    func makePrivateKey() -> Curve25519.KeyAgreement.PrivateKey {
        Curve25519.KeyAgreement.PrivateKey() // TODO: Store private key when creating
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
    
    func set(agreementKeys: AgreementKeys, topic: String) throws {
//        let agreement = agreementKeys.sharedSecret + agreementKeys.publicKey
        let agreement = agreementKeys.sharedSecret + agreementKeys.publicKey.rawRepresentation
        try keychain.add(agreement, forKey: topic)
    }
    
    func getAgreementKeys(for topic: String) -> AgreementKeys? {
        guard let agreement = try? keychain.read(key: topic) as Data else {
            return nil
        }
        let (sharedSecret, publicKey) = split(concatinatedAgreementKeys: agreement)
        return AgreementKeys(sharedSecret: sharedSecret, publicKey: try! Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKey))
    }
    
//    func _set(agreementKeys: AgreementKeys, topic: String) {
//        let agreement = agreementKeys.sharedSecret + agreementKeys.publicKey
//        do {
//            try keychain.add(agreement, forKey: topic)
//        } catch {
//            print("Error adding agreement keys: \(error)")
//        }
//    }
//    
//    func _getAgreementKeys(for topic: String) -> AgreementKeys? {
//        guard let agreement = try? keychain.read(key: topic) as Data else {
//            return nil
//        }
//        let (sharedSecret, publicKey) = split(concatinatedAgreementKeys: agreement)
//        return AgreementKeys(sharedSecret: sharedSecret, publicKey: publicKey)
//    }
    
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

extension Crypto {
    
    static func generateAgreementKeys(peerPublicKey: Data, privateKey: Curve25519.KeyAgreement.PrivateKey, sharedInfo: Data = Data()) throws -> AgreementKeys {
        let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKey)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let rawSharedSecret = sharedSecret.withUnsafeBytes { return Data(Array($0)) }
        return AgreementKeys(sharedSecret: rawSharedSecret, publicKey: privateKey.publicKey)
    }
}
