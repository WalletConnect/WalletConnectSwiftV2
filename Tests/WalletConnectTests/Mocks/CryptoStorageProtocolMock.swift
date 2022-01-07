import Foundation
@testable import WalletConnect

final class CryptoStorageProtocolMock: CryptoStorageProtocol {
    
    func createX25519KeyPair() throws -> AgreementPublicKey {
        defer { privateKeyStub = AgreementPrivateKey() }
        try setPrivateKey(privateKeyStub)
        return privateKeyStub.publicKey
    }
    
    func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementKeys {
        // TODO: Fix mock
        guard let privateKey = try getPrivateKey(for: selfPublicKey) else {
            fatalError() // TODO: handle error
        }
        let peerPublicKey = try AgreementPublicKey(rawRepresentation: Data(hex: hexRepresentation))
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let rawSecret = sharedSecret.withUnsafeBytes { return Data(Array($0)) }
        return AgreementKeys(sharedSecret: rawSecret, publicKey: privateKey.publicKey)
    }
    
    
    var privateKeyStub = AgreementPrivateKey()
    
    private(set) var privateKeys: [String: AgreementPrivateKey] = [:]
    private(set) var agreementKeys: [String: AgreementKeys] = [:]
    
    func makePrivateKey() -> AgreementPrivateKey {
        defer { privateKeyStub = AgreementPrivateKey() }
        return privateKeyStub
    }
    
    func setPrivateKey(_ privateKey: AgreementPrivateKey) throws {
        privateKeys[privateKey.publicKey.rawRepresentation.toHexString()] = privateKey
    }
    
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey? {
        privateKeys[publicKey.rawRepresentation.toHexString()]
    }
    
    func setAgreementKeys(_ agreementKeys: AgreementKeys, topic: String) {
        self.agreementKeys[topic] = agreementKeys
    }
    
    func getAgreementKeys(for topic: String) -> AgreementKeys? {
        agreementKeys[topic]
    }
    
    func deletePrivateKey(for publicKey: String) {
        privateKeys[publicKey] = nil
    }
    
    func deleteAgreementKeys(for topic: String) {
        agreementKeys[topic] = nil
    }
}

extension CryptoStorageProtocolMock {
    
    func hasPrivateKey(for publicKeyHex: String) -> Bool {
        privateKeys[publicKeyHex] != nil
    }
    
    func hasAgreementKeys(for topic: String) -> Bool {
        agreementKeys[topic] != nil
    }
}
