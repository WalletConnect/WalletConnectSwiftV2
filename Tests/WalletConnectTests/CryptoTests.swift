
import Foundation
import XCTest
import CryptoKit
@testable import WalletConnect

extension Curve25519.KeyAgreement.PrivateKey: Equatable {
    
    public static func == (lhs: Curve25519.KeyAgreement.PrivateKey, rhs: Curve25519.KeyAgreement.PrivateKey) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
}

class CryptoTests: XCTestCase {
    var crypto: Crypto!

    override func setUp() {
        crypto = Crypto(keychain: KeychainStorageMock())
    }

    override func tearDown() {
        crypto = nil
    }
    
    func testSetGetPrivateKey() {
        let privateKey = try! Curve25519.KeyAgreement.PrivateKey(rawRepresentation: CryptoTestData._publicKeyA)
        let publicKey = privateKey.publicKey
        XCTAssertNil(try! crypto.getPrivateKey(for: publicKey))
        try! crypto.set(privateKey: privateKey)
        let derivedPrivateKey = try! crypto.getPrivateKey(for: publicKey)
        XCTAssertEqual(privateKey, derivedPrivateKey)
    }
    
    func testSetGetAgreementKeys() {
        let topic = "topic"
        XCTAssertNil(crypto.getAgreementKeys(for: topic))
        let agreementKeys = AgreementKeys(
            sharedSecret: CryptoTestData.expectedSharedSecret,
            publicKey: try! Curve25519.KeyAgreement.PublicKey(rawRepresentation: CryptoTestData._publicKeyA))
        try? crypto.set(agreementKeys: agreementKeys, topic: topic)
        let derivedAgreementKeys = crypto.getAgreementKeys(for: topic)
        XCTAssertEqual(agreementKeys, derivedAgreementKeys)
    }
    
    func testX25519Agreement() {
        let privateKeyA = try! Curve25519.KeyAgreement.PrivateKey(rawRepresentation: CryptoTestData._privateKeyA)
        let privateKeyB = try! Curve25519.KeyAgreement.PrivateKey(rawRepresentation: CryptoTestData._privateKeyB)
        let agreementKeysA = try! Crypto.generateAgreementKeys(peerPublicKey: privateKeyB.publicKey.rawRepresentation, privateKey: privateKeyA)
        let agreementKeysB = try! Crypto.generateAgreementKeys(peerPublicKey: privateKeyA.publicKey.rawRepresentation, privateKey: privateKeyB)
        XCTAssertEqual(agreementKeysA.sharedSecret, agreementKeysB.sharedSecret)
        XCTAssertEqual(agreementKeysA.sharedSecret, CryptoTestData.expectedSharedSecret)
    }
}
