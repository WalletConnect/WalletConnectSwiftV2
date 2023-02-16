import Foundation
@testable import WalletConnectKMS

final class KeyManagementServiceMock: KeyManagementServiceProtocol {
    private(set) var privateKeys: [String: AgreementPrivateKey] = [:]
    private(set) var symmetricKeys: [String: SymmetricKey] = [:]
    private(set) var agreementKeys: [String: AgreementKeys] = [:]
    private(set) var publicKeys: [String: AgreementPublicKey] = [:]

    func getSymmetricKeyRepresentable(for topic: String) -> Data? {
        if let key = getAgreementSecret(for: topic)?.sharedKey {
            return key.rawRepresentation
        } else {
            return getSymmetricKey(for: topic)?.rawRepresentation
        }
    }

    func createSymmetricKey(_ topic: String) throws -> SymmetricKey {
        let key = SymmetricKey()
        try setSymmetricKey(key, for: topic)
        return key
    }

    func setSymmetricKey(_ symmetricKey: SymmetricKey, for topic: String) throws {
        symmetricKeys[topic] = symmetricKey
    }

    func getSymmetricKey(for topic: String) -> SymmetricKey? {
        symmetricKeys[topic]
    }

    func deleteSymmetricKey(for topic: String) {
        symmetricKeys[topic] = nil
    }

    func deletePublicKey(for topic: String) {
        publicKeys[topic] = nil
    }

    func getPublicKey(for topic: String) -> AgreementPublicKey? {
        publicKeys[topic]
    }

    func createX25519KeyPair() throws -> AgreementPublicKey {
        let privateKey = AgreementPrivateKey()
        try setPrivateKey(privateKey)
        return privateKey.publicKey
    }

    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementKeys {
        // TODO: Fix mock
        guard let privateKey = try getPrivateKey(for: selfPublicKey) else {
            fatalError() // TODO: handle error
        }
        let peerPublicKey = try AgreementPublicKey(rawRepresentation: Data(hex: hexRepresentation))
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let sharedKey = sharedSecret.deriveSymmetricKey()
        return AgreementKeys(sharedKey: sharedKey, publicKey: privateKey.publicKey)
    }

    func setPrivateKey(_ privateKey: AgreementPrivateKey) throws {
        privateKeys[privateKey.publicKey.rawRepresentation.toHexString()] = privateKey
    }

    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey? {
        privateKeys[publicKey.rawRepresentation.toHexString()]
    }

    func getPrivateKey(for publicKey: String) throws -> AgreementPrivateKey? {
        privateKeys[publicKey]
    }

    func setPublicKey(publicKey: AgreementPublicKey, for topic: String) throws {
        publicKeys[topic] = publicKey
    }

    func setAgreementSecret(_ agreementKeys: AgreementKeys, topic: String) {
        self.agreementKeys[topic] = agreementKeys
    }

    func getAgreementSecret(for topic: String) -> AgreementKeys? {
        agreementKeys[topic]
    }

    func deletePrivateKey(for publicKey: String) {
        privateKeys[publicKey] = nil
    }

    func deleteAgreementSecret(for topic: String) {
        agreementKeys[topic] = nil
    }

    func deleteAll() throws {
        privateKeys = [:]
        symmetricKeys = [:]
        agreementKeys = [:]
    }
}

extension KeyManagementServiceMock {

    func hasPrivateKey(for publicKeyHex: String) -> Bool {
        privateKeys[publicKeyHex] != nil
    }

    func hasAgreementSecret(for topic: String) -> Bool {
        agreementKeys[topic] != nil
    }

    func hasSymmetricKey(for topic: String) -> Bool {
        symmetricKeys[topic] != nil
    }
}
