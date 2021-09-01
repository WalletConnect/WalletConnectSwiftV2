
import Foundation
import XCTest
@testable import WalletConnect

class CryptoTests: XCTestCase {
    var crypto: Crypto!

    override func setUp() {
        crypto = Crypto(keychain: DictionaryKeychain())
    }

    override func tearDown() {
        crypto = nil
    }
    
    func testSetGetPrivateKey() {
        let privateKey = try! Crypto.X25519.PrivateKey(raw: CryptoTestData._publicKeyA)
        let publicKey = privateKey.publicKey
        XCTAssertNil(try! crypto.getPrivateKey(for: publicKey))
        crypto.set(privateKey: privateKey)
        let derivedPrivateKey = try! crypto.getPrivateKey(for: publicKey)
        XCTAssertEqual(privateKey, derivedPrivateKey)
    }
    
    func testSetGetAgreementKeys() {
        let topic = "topic"
        XCTAssertNil(crypto.getAgreementKeys(for: topic))
        let agreementKeys = Crypto.X25519.AgreementKeys(sharedSecret: CryptoTestData.expectedSharedSecret, publicKey: CryptoTestData._publicKeyA)
        crypto.set(agreementKeys: agreementKeys, topic: topic)
        let derivedAgreementKeys = crypto.getAgreementKeys(for: topic)
        XCTAssertEqual(agreementKeys, derivedAgreementKeys)
    }
    
    func testX25519Agreement() {
        let privateKeyA = try! Crypto.X25519.PrivateKey(raw: CryptoTestData._privateKeyA)
        let privateKeyB = try! Crypto.X25519.PrivateKey(raw: CryptoTestData._privateKeyB)
        let agreementKeysA = try! Crypto.X25519.generateAgreementKeys(peerPublicKey: privateKeyB.publicKey, privateKey: privateKeyA)
        let agreementKeysB = try! Crypto.X25519.generateAgreementKeys(peerPublicKey: privateKeyA.publicKey, privateKey: privateKeyB)
        XCTAssertEqual(agreementKeysA.sharedSecret, agreementKeysB.sharedSecret)
        XCTAssertEqual(agreementKeysA.sharedSecret, CryptoTestData.expectedSharedSecret)
    }
}
