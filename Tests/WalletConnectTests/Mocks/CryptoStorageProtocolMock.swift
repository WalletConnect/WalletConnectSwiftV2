import Foundation
import CryptoKit
@testable import WalletConnect

final class CryptoStorageProtocolMock: CryptoStorageProtocol {
    
    var privateKeyStub = Curve25519.KeyAgreement.PrivateKey()
    
    private(set) var _privateKeys: [String: Curve25519.KeyAgreement.PrivateKey] = [:]
    
    func makePrivateKey() -> Curve25519.KeyAgreement.PrivateKey {
        defer { privateKeyStub = Curve25519.KeyAgreement.PrivateKey() }
        return privateKeyStub
    }
    
    func set(privateKey: Curve25519.KeyAgreement.PrivateKey) throws {
        _privateKeys[privateKey.publicKey.rawRepresentation.toHexString()] = privateKey
    }
    
    func getPrivateKey(for publicKey: Curve25519.KeyAgreement.PublicKey) throws -> Curve25519.KeyAgreement.PrivateKey? {
        _privateKeys[publicKey.rawRepresentation.toHexString()]
    }
    
    
//    var privateKeyStub = Crypto.X25519.PrivateKey()
    
//    private(set) var privateKeys: [String: Crypto.X25519.PrivateKey] = [:]
    private(set) var agreementKeys: [String: Crypto.X25519.AgreementKeys] = [:]
    
//    func generatePrivateKey() -> Crypto.X25519.PrivateKey {
//        defer { privateKeyStub = Crypto.X25519.PrivateKey() }
//        return privateKeyStub
//    }
//
//    func set(privateKey: Crypto.X25519.PrivateKey) {
//        privateKeys[privateKey.publicKey.toHexString()] = privateKey
//    }
    
    func set(agreementKeys: Crypto.X25519.AgreementKeys, topic: String) {
        self.agreementKeys[topic] = agreementKeys
    }
    
//    func getPrivateKey(for publicKey: Data) throws -> Crypto.X25519.PrivateKey? {
//        privateKeys[publicKey.toHexString()]
//    }
    
    func getAgreementKeys(for topic: String) -> Crypto.X25519.AgreementKeys? {
        agreementKeys[topic]
    }
    
    func deletePrivateKey(for publicKey: String) {
//        privateKeys[publicKey] = nil
        _privateKeys[publicKey] = nil
    }
    
    func deleteAgreementKeys(for topic: String) {
        agreementKeys[topic] = nil
    }
}

extension CryptoStorageProtocolMock {
    
    func hasPrivateKey(for publicKeyHex: String) -> Bool {
        _privateKeys[publicKeyHex] != nil
    }
    
//    func hasLegacyPrivateKey(for publicKey: String) -> Bool {
////        privateKeys[publicKey] != nil
//        false
//    }
    
    func hasAgreementKeys(for topic: String) -> Bool {
        agreementKeys[topic] != nil
    }
}
