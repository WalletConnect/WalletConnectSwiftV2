
import Foundation
import XCTest
@testable import WalletConnect_Swift

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
        let agreementKeys = Crypto.X25519.AgreementKeys(sharedKey: CryptoTestData.expectedSharedSecret, publicKey: CryptoTestData._publicKeyA)
        crypto.set(agreementKeys: agreementKeys, topic: topic)
        let derivedAgreementKeys = crypto.getAgreementKeys(for: topic)
        XCTAssertEqual(agreementKeys, derivedAgreementKeys)
    }
    
    func testX25519Agreement() {
        let peerPublicKey = CryptoTestData._publicKeyB
        let privateKey = try! Crypto.X25519.PrivateKey(raw: CryptoTestData._privateKeyA)
        let agreementKeys = try! Crypto.X25519.generateAgreementKeys(peerPublicKey: peerPublicKey, privateKey: privateKey)
        print(agreementKeys.sharedKey.toHexString())
        print(CryptoTestData.expectedSharedSecret.toHexString())
        XCTAssertEqual(agreementKeys.sharedKey, CryptoTestData.expectedSharedSecret)
    }
}
