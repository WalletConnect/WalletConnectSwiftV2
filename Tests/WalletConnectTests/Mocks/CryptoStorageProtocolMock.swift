import Foundation
import CryptoKit
@testable import WalletConnect

final class CryptoStorageProtocolMock: CryptoStorageProtocol {
    
    var privateKeyStub = Curve25519.KeyAgreement.PrivateKey()
    
    private(set) var privateKeys: [String: Curve25519.KeyAgreement.PrivateKey] = [:]
    private(set) var agreementKeys: [String: AgreementKeys] = [:]
    
    func makePrivateKey() -> Curve25519.KeyAgreement.PrivateKey {
        defer { privateKeyStub = Curve25519.KeyAgreement.PrivateKey() }
        return privateKeyStub
    }
    
    func set(privateKey: Curve25519.KeyAgreement.PrivateKey) throws {
        privateKeys[privateKey.publicKey.rawRepresentation.toHexString()] = privateKey
    }
    
    func getPrivateKey(for publicKey: Curve25519.KeyAgreement.PublicKey) throws -> Curve25519.KeyAgreement.PrivateKey? {
        privateKeys[publicKey.rawRepresentation.toHexString()]
    }
    
    func set(agreementKeys: AgreementKeys, topic: String) {
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
