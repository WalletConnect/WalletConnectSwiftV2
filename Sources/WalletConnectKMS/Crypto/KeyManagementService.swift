import Foundation

public protocol KeyManagementServiceProtocol {
    func createX25519KeyPair() throws -> AgreementPublicKey
    func createSymmetricKey(_ topic: String) throws -> SymmetricKey
    func setPrivateKey(_ privateKey: AgreementPrivateKey) throws
    func setAgreementSecret(_ agreementSecret: AgreementSecret, topic: String) throws
    func setSymmetricKey(_ symmetricKey: SymmetricKey, for topic: String) throws
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey?
    func getAgreementSecret(for topic: String) throws -> AgreementSecret?
    func getSymmetricKey(for topic: String) throws -> SymmetricKey?
    func getSymmetricKeyRepresentable(for topic: String) -> SymmetricRepresentable?
    func deletePrivateKey(for publicKey: String)
    func deleteAgreementSecret(for topic: String)
    func deleteSymmetricKey(for topic: String)
    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementSecret
}

public class KeyManagementService: KeyManagementServiceProtocol {

    enum Error: Swift.Error {
        case keyNotFound
    }
    
    private var keychain: KeychainStorageProtocol
    
    public init(serviceIdentifier: String) {
        self.keychain =  KeychainStorage(serviceIdentifier:  serviceIdentifier)
    }
    
    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }
    
    public func createX25519KeyPair() throws -> AgreementPublicKey {
        let privateKey = AgreementPrivateKey()
        try setPrivateKey(privateKey)
        return privateKey.publicKey
    }

    public func createSymmetricKey(_ topic: String) throws -> SymmetricKey {
        let key = SymmetricKey()
        try setSymmetricKey(key, for: topic)
        return key
    }
    
    public func setSymmetricKey(_ symmetricKey: SymmetricKey, for topic: String) throws {
        try keychain.add(symmetricKey, forKey: topic)
    }
    
    public func setPrivateKey(_ privateKey: AgreementPrivateKey) throws {
        try keychain.add(privateKey, forKey: privateKey.publicKey.hexRepresentation)
    }
    
    public func setAgreementSecret(_ agreementSecret: AgreementSecret, topic: String) throws {
        try keychain.add(agreementSecret, forKey: topic)
    }
    
    public func getSymmetricKey(for topic: String) throws -> SymmetricKey? {
        do {
            return try keychain.read(key: topic) as SymmetricKey
        } catch {
            return nil
        }
    }
    
    public func getSymmetricKeyRepresentable(for topic: String) -> SymmetricRepresentable? {
        if let key = try? getAgreementSecret(for: topic) {
            return key
        } else {
            return try? getSymmetricKey(for: topic)
        }
    }
    
    public func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey? {
        do {
            return try keychain.read(key: publicKey.hexRepresentation) as AgreementPrivateKey
        } catch let error where (error as? KeychainError)?.status == errSecItemNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    public func getAgreementSecret(for topic: String) throws -> AgreementSecret? {
        do {
            return try keychain.read(key: topic) as AgreementSecret
        } catch {
            return nil
        }
    }
    
    public func deletePrivateKey(for publicKey: String) {
        do {
            try keychain.delete(key: publicKey)
        } catch {
            print("Error deleting private key: \(error)")
        }
    }
    
    public func deleteAgreementSecret(for topic: String) {
        do {
            try keychain.delete(key: topic)
        } catch {
            print("Error deleting agreement key: \(error)")
        }
    }
    
    public func deleteSymmetricKey(for topic: String) {
        do {
            try keychain.delete(key: topic)
        } catch {
            print("Error deleting symmetric key: \(error)")
        }
    }
    
    public func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementSecret {
        guard let privateKey = try getPrivateKey(for: selfPublicKey) else {
            print("Key Agreement Error: Private key not found for public key: \(selfPublicKey.hexRepresentation)")
            throw KeyManagementService.Error.keyNotFound
        }
        return try KeyManagementService.generateAgreementSecret(from: privateKey, peerPublicKey: hexRepresentation)
    }
    
    static func generateAgreementSecret(from privateKey: AgreementPrivateKey, peerPublicKey hexRepresentation: String) throws -> AgreementSecret {
        let peerPublicKey = try AgreementPublicKey(rawRepresentation: Data(hex: hexRepresentation))
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let rawSecret = sharedSecret.withUnsafeBytes { return Data(Array($0)) }
        return AgreementSecret(sharedSecret: rawSecret, publicKey: privateKey.publicKey)
    }
}
