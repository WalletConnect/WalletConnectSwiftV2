import Foundation
import XCTest
import WalletConnectUtils
import TestingUtils
@testable import WalletConnectVerify

@available(iOS 14.0, *)
@available(macOS 11.0, *)
class AppAttestationRegistrerTests: XCTestCase {
    var attestKeyGenerator: AttestKeyGeneratingMock!
    var attestChallengeProvider: AttestChallengeProvidingMock!
    var keyAttestationService: KeyAttestingMock!
    var sut: AppAttestationRegistrer!
    var keyIdStorage: CodableStore<String>!

    override func setUp() {
        let kvStorage = RuntimeKeyValueStorage()

        keyIdStorage = CodableStore(defaults: kvStorage, identifier: "")
        attestKeyGenerator = AttestKeyGeneratingMock()
        attestChallengeProvider = AttestChallengeProvidingMock()
        keyAttestationService = KeyAttestingMock()

        sut = AppAttestationRegistrer(
            logger: ConsoleLoggerMock(),
            keyIdStorage: keyIdStorage,
            attestKeyGenerator: attestKeyGenerator,
            attestChallengeProvider: attestChallengeProvider,
            keyAttestationService: keyAttestationService)
    }

    func testAttestation() async {
        try! await sut.registerAttestationIfNeeded()
        XCTAssertTrue(attestKeyGenerator.keysGenerated)
        XCTAssertTrue(attestChallengeProvider.challengeProvided)
        XCTAssertTrue(keyAttestationService.keyAttested)
    }

    func testAttestationAlreadyRegistered() async {
        keyIdStorage.set("123", forKey: "attested_key_id")
        try! await sut.registerAttestationIfNeeded()
        XCTAssertFalse(attestKeyGenerator.keysGenerated)
        XCTAssertFalse(attestChallengeProvider.challengeProvided)
        XCTAssertFalse(keyAttestationService.keyAttested)
    }
}
