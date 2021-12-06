import Foundation
@testable import WalletConnect

final class CryptoStorageProtocolMock: CryptoStorageProtocol {
    
    var privateKeyStub = Crypto.X25519.PrivateKey()
    
    private(set) var privateKeys: [String: Crypto.X25519.PrivateKey] = [:]
    private(set) var agreementKeys: [String: Crypto.X25519.AgreementKeys] = [:]
    
    func generatePrivateKey() -> Crypto.X25519.PrivateKey {
        defer { privateKeyStub = Crypto.X25519.PrivateKey() }
        return privateKeyStub
    }
    
    func set(privateKey: Crypto.X25519.PrivateKey) {
        privateKeys[privateKey.publicKey.toHexString()] = privateKey
    }
    
    func set(agreementKeys: Crypto.X25519.AgreementKeys, topic: String) {
        self.agreementKeys[topic] = agreementKeys
    }
    
    func getPrivateKey(for publicKey: Data) throws -> Crypto.X25519.PrivateKey? {
        privateKeys[publicKey.toHexString()]
    }
    
    func getAgreementKeys(for topic: String) -> Crypto.X25519.AgreementKeys? {
        fatalError()
    }
    
    func deletePrivateKey(for publicKey: String) {
        
    }
    
    func deleteAgreementKeys(for topic: String) {
        
    }
}

extension CryptoStorageProtocolMock {
    
    func hasPrivateKey(for publicKey: String) -> Bool {
        privateKeys[publicKey] != nil
    }
    
    func hasAgreementKeys(for topic: String) -> Bool {
        agreementKeys[topic] != nil
    }
}
