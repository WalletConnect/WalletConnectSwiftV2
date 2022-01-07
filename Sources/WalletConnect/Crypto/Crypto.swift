import Foundation

// Maybe AgreementSecret?
struct AgreementSecret: Equatable {
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
    func setPrivateKey(_ privateKey: AgreementPrivateKey) throws
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey?
    func setAgreementSecret(_ agreementSecret: AgreementSecret, topic: String) throws
    func getAgreementSecret(for topic: String) -> AgreementSecret?
    func deletePrivateKey(for publicKey: String)
    func deleteAgreementSecret(for topic: String)
    
    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementSecret
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
        try setPrivateKey(privateKey)
        return privateKey.publicKey
    }
    
    func setPrivateKey(_ privateKey: AgreementPrivateKey) throws {
        try keychain.add(privateKey.rawRepresentation, forKey: privateKey.publicKey.rawRepresentation.toHexString())
    }
    
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey? {
        guard let privateKeyData = try? keychain.read(key: publicKey.rawRepresentation.toHexString()) as Data else {
            return nil
        }
        return try AgreementPrivateKey(rawRepresentation: privateKeyData)
    }
    
    func setAgreementSecret(_ agreementKeys: AgreementSecret, topic: String) throws {
        let agreement = agreementKeys.sharedSecret + agreementKeys.publicKey.rawRepresentation
        try keychain.add(agreement, forKey: topic)
    }
    
    func getAgreementSecret(for topic: String) -> AgreementSecret? {
        guard let agreement = try? keychain.read(key: topic) as Data else {
            return nil
        }
        let (sharedSecret, publicKey) = split(concatinatedAgreementSecret: agreement)
        return AgreementSecret(sharedSecret: sharedSecret, publicKey: try! AgreementPublicKey(rawRepresentation: publicKey))
    }
    
    func deletePrivateKey(for publicKey: String) {
        do {
            try keychain.delete(key: publicKey)
        } catch {
            print("Error deleting private key: \(error)")
        }
    }
    
    func deleteAgreementSecret(for topic: String) {
        do {
            try keychain.delete(key: topic)
        } catch {
            print("Error deleting agreement key: \(error)")
        }
    }
    
    private func split(concatinatedAgreementSecret: Data) -> (Data, Data) {
        let sharedSecret = concatinatedAgreementSecret.subdata(in: 0..<32)
        let publicKey = concatinatedAgreementSecret.subdata(in: 32..<64)
        return (sharedSecret, publicKey)
    }
}

extension Crypto {
    
    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementSecret {
        guard let privateKey = try getPrivateKey(for: selfPublicKey) else {
            fatalError() // TODO: handle error
        }
        let peerPublicKey = try AgreementPublicKey(rawRepresentation: Data(hex: hexRepresentation))
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let rawSecret = sharedSecret.withUnsafeBytes { return Data(Array($0)) }
        return AgreementSecret(sharedSecret: rawSecret, publicKey: privateKey.publicKey)
    }
    
    static func generateAgreementSecret(peerPublicKey: Data, privateKey: AgreementPrivateKey, sharedInfo: Data = Data()) throws -> AgreementSecret {
//        let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKey)
        let peerPublicKey = try AgreementPublicKey(rawRepresentation: peerPublicKey)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let rawSharedSecret = sharedSecret.withUnsafeBytes { return Data(Array($0)) }
        return AgreementSecret(sharedSecret: rawSharedSecret, publicKey: privateKey.publicKey)
    }
}
