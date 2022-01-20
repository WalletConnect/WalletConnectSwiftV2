import Foundation

// TODO: Come up with better naming conventions
protocol CryptoStorageProtocol {
    func createX25519KeyPair() throws -> AgreementPublicKey
    func setPrivateKey(_ privateKey: AgreementPrivateKey) throws
    func setAgreementSecret(_ agreementSecret: AgreementSecret, topic: String) throws
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey?
    func getAgreementSecret(for topic: String) throws -> AgreementSecret?
    func deletePrivateKey(for publicKey: String)
    func deleteAgreementSecret(for topic: String)
    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementSecret
}

class Crypto: CryptoStorageProtocol {
    
    private var keychain: KeychainStorageProtocol
    
    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }
    
    func createX25519KeyPair() throws -> AgreementPublicKey {
        let privateKey = AgreementPrivateKey()
        try setPrivateKey(privateKey)
        return privateKey.publicKey
    }
    
    func setPrivateKey(_ privateKey: AgreementPrivateKey) throws {
        try keychain.add(privateKey, forKey: privateKey.publicKey.hexRepresentation)
    }
    
    func setAgreementSecret(_ agreementSecret: AgreementSecret, topic: String) throws {
        try keychain.add(agreementSecret, forKey: topic)
    }
    
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey? {
        do {
            return try keychain.read(key: publicKey.hexRepresentation) as AgreementPrivateKey
        } catch let error where (error as? KeychainError)?.status == errSecItemNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    func getAgreementSecret(for topic: String) throws -> AgreementSecret? {
        do {
            return try keychain.read(key: topic) as AgreementSecret
        } catch let error where (error as? KeychainError)?.status == errSecItemNotFound {
            return nil
        } catch {
            throw error
        }
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
    
    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementSecret {
        guard let privateKey = try getPrivateKey(for: selfPublicKey) else {
            print("Key Agreement Error: Private key not found for public key: \(selfPublicKey.hexRepresentation)")
            throw WalletConnectError.internal(.keyNotFound)
        }
        return try Crypto.generateAgreementSecret(from: privateKey, peerPublicKey: hexRepresentation)
    }
    
    static func generateAgreementSecret(from privateKey: AgreementPrivateKey, peerPublicKey hexRepresentation: String) throws -> AgreementSecret {
        let peerPublicKey = try AgreementPublicKey(rawRepresentation: Data(hex: hexRepresentation))
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let rawSecret = sharedSecret.withUnsafeBytes { return Data(Array($0)) }
        return AgreementSecret(sharedSecret: rawSecret, publicKey: privateKey.publicKey)
    }
}
