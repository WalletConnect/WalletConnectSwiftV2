import XCTest
@testable import WalletConnect

class CryptoTests: XCTestCase {
    
    var crypto: Crypto!

    override func setUp() {
        crypto = Crypto(keychain: KeychainStorageMock())
    }

    override func tearDown() {
        crypto = nil
    }
    
    func testCreateKeyPair() throws {
        let publicKey = try crypto.createX25519KeyPair()
        let privateKey = try crypto.getPrivateKey(for: publicKey)
        XCTAssertNotNil(privateKey)
        XCTAssertEqual(privateKey?.publicKey, publicKey)
    }
    
    func testPrivateKeyRoundTrip() throws {
        let privateKey = AgreementPrivateKey()
        let publicKey = privateKey.publicKey
        XCTAssertNil(try crypto.getPrivateKey(for: publicKey))
        try crypto.setPrivateKey(privateKey)
        let storedPrivateKey = try crypto.getPrivateKey(for: publicKey)
        XCTAssertEqual(privateKey, storedPrivateKey)
    }
    
    func testDeletePrivateKey() throws {
        let privateKey = AgreementPrivateKey()
        let publicKey = privateKey.publicKey
        try crypto.setPrivateKey(privateKey)
        crypto.deletePrivateKey(for: publicKey.hexRepresentation)
        XCTAssertNil(try crypto.getPrivateKey(for: publicKey))
    }
    
    func testAgreementSecretRoundTrip() {
        let topic = "topic"
        XCTAssertNil(crypto.getAgreementSecret(for: topic))
        let agreementKeys = AgreementSecret(
            sharedSecret: CryptoTestData.expectedSharedSecret,
            publicKey: try! AgreementPublicKey(rawRepresentation: CryptoTestData._publicKeyA))
        try? crypto.setAgreementSecret(agreementKeys, topic: topic)
        let storedAgreementSecret = crypto.getAgreementSecret(for: topic)
        XCTAssertEqual(agreementKeys, storedAgreementSecret)
    }
    
    func testDeleteAgreementSecret() {
        let topic = "topic"
        let agreementKeys = AgreementSecret(
            sharedSecret: CryptoTestData.expectedSharedSecret,
            publicKey: try! AgreementPublicKey(rawRepresentation: CryptoTestData._publicKeyA))
        try? crypto.setAgreementSecret(agreementKeys, topic: topic)
        crypto.deleteAgreementSecret(for: topic)
        XCTAssertNil(crypto.getAgreementSecret(for: topic))
    }
    
    func testX25519Agreement() throws {
        let privateKeyA = try AgreementPrivateKey(rawRepresentation: CryptoTestData._privateKeyA)
        let privateKeyB = try AgreementPrivateKey(rawRepresentation: CryptoTestData._privateKeyB)
//        let privateKeyA = AgreementPrivateKey()
//        let privateKeyB = AgreementPrivateKey()
        let agreementKeysA = try Crypto.generateAgreementSecret(peerPublicKey: privateKeyB.publicKey.rawRepresentation, privateKey: privateKeyA)
        let agreementKeysB = try Crypto.generateAgreementSecret(peerPublicKey: privateKeyA.publicKey.rawRepresentation, privateKey: privateKeyB)
        XCTAssertEqual(agreementKeysA.sharedSecret, agreementKeysB.sharedSecret)
        XCTAssertEqual(agreementKeysA.sharedSecret, CryptoTestData.expectedSharedSecret)
    }
}
