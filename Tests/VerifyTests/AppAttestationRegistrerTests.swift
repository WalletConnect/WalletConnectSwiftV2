import Foundation
import XCTest
import WalletConnectUtils
import TestingUtils
@testable import WalletConnectVerify
@testable import WalletConnectSign

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

    func testHash() {
        let string = """
        {"id":1681835052048874,"jsonrpc":"2.0","method":"wc_sessionPropose","params":{"requiredNamespaces":{"eip155":{"methods":["eth_sendTransaction","eth_signTransaction","eth_sign","personal_sign","eth_signTypedData"],"chains":["eip155:1"],"events":["chainChanged","accountsChanged"]}},"optionalNamespaces":{},"relays":[{"protocol":"irn"}],"proposer":{"publicKey":"9644bb921f5628ec3325b4027229976172a4ab71043fe0e1174acfa237f0592b","metadata":{"description":"React App for WalletConnect","url":"http://localhost:3000","icons":["https://avatars.githubusercontent.com/u/37784886"],"name":"React App"}}}}
        """
        let sha256 = string.rawRepresentation.sha256().toHexString()
        print(sha256)
        XCTAssertEqual("c52ef2f630a172c4a3ae7ef5750b7662a904273fc81d1e892c5dd0c508c09583", sha256)
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
