
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

    override func setUp() {
        let kvStorage = RuntimeKeyValueStorage()

        attestKeyGenerator = AttestKeyGeneratingMock()
        attestChallengeProvider = AttestChallengeProvidingMock()
        keyAttestationService = KeyAttestingMock()

        sut = AppAttestationRegistrer(
            logger: ConsoleLoggerMock(),
            keyIdStorage: CodableStore(defaults: kvStorage, identifier: ""),
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

    func testAttestationAlreadyRegistered() {

    }
}
