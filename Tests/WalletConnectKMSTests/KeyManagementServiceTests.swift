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
        XCTAssertNil(kms.getAgreementSecret(for: topic))
        let agreementKeys = AgreementKeys.stub()
        try? kms.setAgreementSecret(agreementKeys, topic: topic)
        let storedAgreementSecret = kms.getAgreementSecret(for: topic)
        XCTAssertEqual(agreementKeys, storedAgreementSecret)
    }

    func testDeleteAgreementSecret() throws {
        let topic = "topic"
        let agreementKeys = AgreementKeys.stub()
        try? kms.setAgreementSecret(agreementKeys, topic: topic)
        kms.deleteAgreementSecret(for: topic)
        XCTAssertNil(kms.getAgreementSecret(for: topic))
    }

    func testGenerateX25519Agreement() throws {
        let privateKeyA = try AgreementPrivateKey(rawRepresentation: CryptoTestData.privateKeyA)
        let privateKeyB = try AgreementPrivateKey(rawRepresentation: CryptoTestData.privateKeyB)
        let agreementSecretA = try KeyManagementService.generateAgreementKey(from: privateKeyA, peerPublicKey: privateKeyB.publicKey.hexRepresentation)
        let agreementSecretB = try KeyManagementService.generateAgreementKey(from: privateKeyB, peerPublicKey: privateKeyA.publicKey.hexRepresentation)
        XCTAssertEqual(agreementSecretA.derivedTopic(), "2c03712132ad2f85adc472a2242e608d67bfecd4362d05012d69a89143fecd16")
        XCTAssertEqual(agreementSecretA.sharedKey, agreementSecretB.sharedKey)
        XCTAssertEqual(agreementSecretA.sharedKey.rawRepresentation, CryptoTestData.expectedSharedKey)
    }

    func testGenerateX25519AgreementRandomKeys() throws {
        let privateKeyA = AgreementPrivateKey()
        let privateKeyB = AgreementPrivateKey()
        let agreementSecretA = try KeyManagementService.generateAgreementKey(from: privateKeyA, peerPublicKey: privateKeyB.publicKey.hexRepresentation)
        let agreementSecretB = try KeyManagementService.generateAgreementKey(from: privateKeyB, peerPublicKey: privateKeyA.publicKey.hexRepresentation)
        XCTAssertEqual(agreementSecretA.sharedKey, agreementSecretB.sharedKey)
    }

    func testPerformKeyAgreement() throws {
        let privateKeySelf = AgreementPrivateKey()
        let privateKeyPeer = AgreementPrivateKey()
        let peerSecret = try KeyManagementService.generateAgreementKey(from: privateKeyPeer, peerPublicKey: privateKeySelf.publicKey.hexRepresentation)
        try kms.setPrivateKey(privateKeySelf)
        let selfSecret = try kms.performKeyAgreement(selfPublicKey: privateKeySelf.publicKey, peerPublicKey: privateKeyPeer.publicKey.hexRepresentation)
        XCTAssertEqual(selfSecret.sharedKey, peerSecret.sharedKey)
    }

    func testPerformKeyAgreementFailure() {
        let publicKeySelf = AgreementPrivateKey().publicKey
        let publicKeyPeer = AgreementPrivateKey().publicKey.hexRepresentation
        XCTAssertThrowsError(try kms.performKeyAgreement(selfPublicKey: publicKeySelf, peerPublicKey: publicKeyPeer)) { error in
            XCTAssert(error.isKeyNotFoundError)
        }
    }

    func testCreateSymmetricKey() {
        let topic = "topic"
        let key = try! kms.createSymmetricKey(topic)
        let retrievedKey = kms.getSymmetricKey(for: topic)
        XCTAssertEqual(key, retrievedKey)
    }

    func testSymmetricKeyRoundTrip() {
        let topic = "topic"
        let key = SymmetricKey()
        try! kms.setSymmetricKey(key, for: topic)
        let retrievedKey = kms.getSymmetricKey(for: topic)
        XCTAssertEqual(key, retrievedKey)
    }

    func testDeleteSymmetricKey() {
        let topic = "topic"
        let key = SymmetricKey()
        try! kms.setSymmetricKey(key, for: topic)
        XCTAssertNotNil(kms.getSymmetricKey(for: topic))
        kms.deleteSymmetricKey(for: topic)
        XCTAssertNil(kms.getSymmetricKey(for: topic))
    }
}
