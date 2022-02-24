import XCTest
@testable import WalletConnectKMS
@testable import TestingUtils

fileprivate extension Error {
    var isKeyNotFoundError: Bool {
        guard case .keyNotFound = self as? KeyManagementService.Error else { return false }
        return true
    }
}

class KeyManagementServiceTests: XCTestCase {
    
    var kms: KeyManagementService!

    override func setUp() {
        kms = KeyManagementService(keychain: KeychainStorageMock())
    }

    override func tearDown() {
        kms = nil
    }
    
    func testCreateKeyPair() throws {
        let publicKey = try kms.createX25519KeyPair()
        let privateKey = try kms.getPrivateKey(for: publicKey)
        XCTAssertNotNil(privateKey)
        XCTAssertEqual(privateKey?.publicKey, publicKey)
    }
    
    func testPrivateKeyRoundTrip() throws {
        let privateKey = AgreementPrivateKey()
        let publicKey = privateKey.publicKey
        XCTAssertNil(try kms.getPrivateKey(for: publicKey))
        try kms.setPrivateKey(privateKey)
        let storedPrivateKey = try kms.getPrivateKey(for: publicKey)
        XCTAssertEqual(privateKey, storedPrivateKey)
    }
    
    func testDeletePrivateKey() throws {
        let privateKey = AgreementPrivateKey()
        let publicKey = privateKey.publicKey
        try kms.setPrivateKey(privateKey)
        kms.deletePrivateKey(for: publicKey.hexRepresentation)
        XCTAssertNil(try kms.getPrivateKey(for: publicKey))
    }
    
    func testAgreementSecretRoundTrip() throws {
        let topic = "topic"
        XCTAssertNil(try kms.getAgreementSecret(for: topic))
        let agreementKeys = AgreementSecret.stub()
        try? kms.setAgreementSecret(agreementKeys, topic: topic)
        let storedAgreementSecret = try kms.getAgreementSecret(for: topic)
        XCTAssertEqual(agreementKeys, storedAgreementSecret)
    }
    
    func testDeleteAgreementSecret() throws {
        let topic = "topic"
        let agreementKeys = AgreementSecret.stub()
        try? kms.setAgreementSecret(agreementKeys, topic: topic)
        kms.deleteAgreementSecret(for: topic)
        XCTAssertNil(try kms.getAgreementSecret(for: topic))
    }
    
    func testGenerateX25519Agreement() throws {
        let privateKeyA = try AgreementPrivateKey(rawRepresentation: CryptoTestData._privateKeyA)
        let privateKeyB = try AgreementPrivateKey(rawRepresentation: CryptoTestData._privateKeyB)
        let agreementSecretA = try KeyManagementService.generateAgreementSecret(from: privateKeyA, peerPublicKey: privateKeyB.publicKey.hexRepresentation)
        let agreementSecretB = try KeyManagementService.generateAgreementSecret(from: privateKeyB, peerPublicKey: privateKeyA.publicKey.hexRepresentation)
        XCTAssertEqual(agreementSecretA.sharedSecret, agreementSecretB.sharedSecret)
        XCTAssertEqual(agreementSecretA.sharedSecret, CryptoTestData.expectedSharedSecret)
    }
    
    func testGenerateX25519AgreementRandomKeys() throws {
        let privateKeyA = AgreementPrivateKey()
        let privateKeyB = AgreementPrivateKey()
        let agreementSecretA = try KeyManagementService.generateAgreementSecret(from: privateKeyA, peerPublicKey: privateKeyB.publicKey.hexRepresentation)
        let agreementSecretB = try KeyManagementService.generateAgreementSecret(from: privateKeyB, peerPublicKey: privateKeyA.publicKey.hexRepresentation)
        XCTAssertEqual(agreementSecretA.sharedSecret, agreementSecretB.sharedSecret)
    }
    
    func testPerformKeyAgreement() throws {
        let privateKeySelf = AgreementPrivateKey()
        let privateKeyPeer = AgreementPrivateKey()
        let peerSecret = try KeyManagementService.generateAgreementSecret(from: privateKeyPeer, peerPublicKey: privateKeySelf.publicKey.hexRepresentation)
        try kms.setPrivateKey(privateKeySelf)
        let selfSecret = try kms.performKeyAgreement(selfPublicKey: privateKeySelf.publicKey, peerPublicKey: privateKeyPeer.publicKey.hexRepresentation)
        XCTAssertEqual(selfSecret.sharedSecret, peerSecret.sharedSecret)
    }
    
    func testPerformKeyAgreementFailure() {
        let publicKeySelf = AgreementPrivateKey().publicKey
        let publicKeyPeer = AgreementPrivateKey().publicKey.hexRepresentation
        XCTAssertThrowsError(try kms.performKeyAgreement(selfPublicKey: publicKeySelf, peerPublicKey: publicKeyPeer)) { error in
            XCTAssert(error.isKeyNotFoundError)
        }
    }
    
    func testCreateSymmetricKey() {
        let key = try! kms.createSymmetricKey()
        let retrievedKey = try! kms.getSymmetricKey(for: key.derivedTopic())
        XCTAssertEqual(key, retrievedKey)
    }
    
    func testSymmetricKeyRoundTrip() {
        let key = SymmetricKey()
        try! kms.setSymmetricKey(key, for: key.derivedTopic())
        let retrievedKey = try! kms.getSymmetricKey(for: key.derivedTopic())
        XCTAssertEqual(key, retrievedKey)
    }
    
    func testDeleteSymmetricKey() {
        let key = SymmetricKey()
        try! kms.setSymmetricKey(key, for: key.derivedTopic())
        XCTAssertNotNil(try! kms.getSymmetricKey(for: key.derivedTopic()))
        kms.deleteSymmetricKey(for: key.derivedTopic())
        XCTAssertNil(try! kms.getSymmetricKey(for: key.derivedTopic()))
    }
}
