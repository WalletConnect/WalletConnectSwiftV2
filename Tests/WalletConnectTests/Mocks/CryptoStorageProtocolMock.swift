import Foundation
@testable import WalletConnect

final class CryptoStorageProtocolMock: CryptoStorageProtocol {
    
    var privateKeyStub = AgreementPrivateKey()
    
    private(set) var privateKeys: [String: AgreementPrivateKey] = [:]
    private(set) var agreementKeys: [String: AgreementKeys] = [:]
    
    func makePrivateKey() -> AgreementPrivateKey {
        defer { privateKeyStub = AgreementPrivateKey() }
        return privateKeyStub
    }
    
    func set(privateKey: AgreementPrivateKey) throws {
        privateKeys[privateKey.publicKey.rawRepresentation.toHexString()] = privateKey
    }
    
    func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey? {
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
