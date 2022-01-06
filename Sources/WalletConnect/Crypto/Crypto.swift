import Foundation
import CryptoKit

struct AgreementKeys: Equatable {
    let sharedSecret: Data
//    let publicKey: Curve25519.KeyAgreement.PublicKey
    let publicKey: AgreementPublicKey
    
    func derivedTopic() -> String {
        sharedSecret.sha256().toHexString()
    }
}

// TODO: Come up with better naming conventions
protocol CryptoStorageProtocol {
    func makePrivateKey() -> AgreementPrivateKey
    func createX25519KeyPair() throws -> AgreementPublicKey
    func set(privateKey: AgreementPrivateKey) throws
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey?
    func set(agreementKeys: AgreementKeys, topic: String) throws
    func getAgreementKeys(for topic: String) -> AgreementKeys?
    func deletePrivateKey(for publicKey: String)
    func deleteAgreementKeys(for topic: String)
    
    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementKeys
}

class Crypto: CryptoStorageProtocol {
    
    private var keychain: KeychainStorageProtocol
    
    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }
    
    func makePrivateKey() -> AgreementPrivateKey {
        AgreementPrivateKey()
    }
    
    func createX25519KeyPair() throws -> AgreementPublicKey {
        let privateKey = AgreementPrivateKey()
        try set(privateKey: privateKey)
        return privateKey.publicKey
    }
    
    func set(privateKey: AgreementPrivateKey) throws {
        try keychain.add(privateKey.rawRepresentation, forKey: privateKey.publicKey.rawRepresentation.toHexString())
    }
    
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey? {
        guard let privateKeyData = try? keychain.read(key: publicKey.rawRepresentation.toHexString()) as Data else {
            return nil
        }
        return try AgreementPrivateKey(rawRepresentation: privateKeyData)
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
        let agreement = agreementKeys.sharedSecret + agreementKeys.publicKey.rawRepresentation
        try keychain.add(agreement, forKey: topic)
    }
    
    func getAgreementKeys(for topic: String) -> AgreementKeys? {
        guard let agreement = try? keychain.read(key: topic) as Data else {
            return nil
        }
        let (sharedSecret, publicKey) = split(concatinatedAgreementKeys: agreement)
//        return AgreementKeys(sharedSecret: sharedSecret, publicKey: try! Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKey))
        return AgreementKeys(sharedSecret: sharedSecret, publicKey: try! AgreementPublicKey(rawRepresentation: publicKey))
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

extension Crypto {
    
    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementKeys {
        guard let privateKey = try getPrivateKey(for: selfPublicKey) else {
            fatalError() // TODO: handle error
        }
        let peerPublicKey = try AgreementPublicKey(rawRepresentation: Data(hex: hexRepresentation))
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let rawSecret = sharedSecret.withUnsafeBytes { return Data(Array($0)) }
        return AgreementKeys(sharedSecret: rawSecret, publicKey: privateKey.publicKey)
    }
    
    static func generateAgreementKeys(peerPublicKey: Data, privateKey: AgreementPrivateKey, sharedInfo: Data = Data()) throws -> AgreementKeys {
//        let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKey)
        let peerPublicKey = try AgreementPublicKey(rawRepresentation: peerPublicKey)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let rawSharedSecret = sharedSecret.withUnsafeBytes { return Data(Array($0)) }
        return AgreementKeys(sharedSecret: rawSharedSecret, publicKey: privateKey.publicKey)
    }
}
