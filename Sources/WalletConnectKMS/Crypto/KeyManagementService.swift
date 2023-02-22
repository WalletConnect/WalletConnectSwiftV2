import Foundation

public protocol KeyManagementServiceProtocol {
    func createX25519KeyPair() throws -> AgreementPublicKey
    func createSymmetricKey(_ topic: String) throws -> SymmetricKey
    func setPrivateKey(_ privateKey: AgreementPrivateKey) throws
    func setPublicKey(publicKey: AgreementPublicKey, for topic: String) throws
    func setAgreementSecret(_ agreementSecret: AgreementKeys, topic: String) throws
    func setSymmetricKey(_ symmetricKey: SymmetricKey, for topic: String) throws
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey?
    func getAgreementSecret(for topic: String) -> AgreementKeys?
    func getSymmetricKey(for topic: String) -> SymmetricKey?
    func getSymmetricKeyRepresentable(for topic: String) -> Data?
    func getPublicKey(for topic: String) -> AgreementPublicKey?
    func deletePrivateKey(for publicKey: String)
    func deleteAgreementSecret(for topic: String)
    func deleteSymmetricKey(for topic: String)
    func deletePublicKey(for topic: String)
    func deleteAll() throws
    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementKeys
}

public class KeyManagementService: KeyManagementServiceProtocol {
    enum Error: Swift.Error {
        case keyNotFound
    }

    private var keychain: KeychainStorageProtocol

    public init(keychain: KeychainStorageProtocol) {
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

    public func setPublicKey(publicKey: AgreementPublicKey, for topic: String) throws {
        try keychain.add(publicKey, forKey: topic)
    }

    public func setAgreementSecret(_ agreementSecret: AgreementKeys, topic: String) throws {
        try keychain.add(agreementSecret, forKey: topic)
    }

    public func getSymmetricKey(for topic: String) -> SymmetricKey? {
        do {
            return try keychain.read(key: topic) as SymmetricKey
        } catch {
            return nil
        }
    }

    public func getSymmetricKeyRepresentable(for topic: String) -> Data? {
        if let key = getAgreementSecret(for: topic)?.sharedKey {
            return key.rawRepresentation
        } else {
            return getSymmetricKey(for: topic)?.rawRepresentation
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

    public func getAgreementSecret(for topic: String) -> AgreementKeys? {
        do {
            return try keychain.read(key: topic) as AgreementKeys
        } catch {
            return nil
        }
    }

    public func getPublicKey(for topic: String) -> AgreementPublicKey? {
        do {
            return try keychain.read(key: topic) as AgreementPublicKey
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

    public func deletePublicKey(for topic: String) {
        do {
            try keychain.delete(key: topic)
        } catch {
            print("Error deleting public key: \(error)")
        }
    }

    public func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementKeys {
        guard let privateKey = try getPrivateKey(for: selfPublicKey) else {
            print("Key Agreement Error: Private key not found for public key: \(selfPublicKey.hexRepresentation)")
            throw KeyManagementService.Error.keyNotFound
        }
        return try KeyManagementService.generateAgreementKey(from: privateKey, peerPublicKey: hexRepresentation)
    }

    public func deleteAll() throws {
        try keychain.deleteAll()
    }

    static func generateAgreementKey(from privateKey: AgreementPrivateKey, peerPublicKey hexRepresentation: String) throws -> AgreementKeys {
        let peerPublicKey = try AgreementPublicKey(rawRepresentation: Data(hex: hexRepresentation))
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let sharedKey = sharedSecret.deriveSymmetricKey()
        return AgreementKeys(sharedKey: sharedKey, publicKey: privateKey.publicKey)
    }
}
