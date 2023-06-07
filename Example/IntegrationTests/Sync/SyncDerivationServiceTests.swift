import Foundation
import XCTest
@testable import WalletConnectSync
@testable import WalletConnectSigner

class SyncDerivationServiceTests: XCTestCase {

    func testDerivation() throws {
        let account = Account("eip155:1:0x1FF34C90a0850Fe7227fcFA642688b9712477482")!
        let signature = "0xc91265eadb1473d90f8d49d31b7016feb7f7761a2a986ca2146a4b8964f3357569869680154927596a5829ceea925f4196b8a853a29c2c1d5915832fc9f1c6a01c"
        let keychain = KeychainStorageMock()
        let syncStorage = SyncSignatureStore(keychain: keychain)
        let kms = KeyManagementService(keychain: keychain)
        let derivationService = SyncDerivationService(
            syncStorage: syncStorage,
            bip44: DefaultBIP44Provider(),
            kms: kms
        )

        try syncStorage.saveSignature(signature, for: account)

        let topic = try derivationService.deriveTopic(account: account, store: "my-user-profile")

        XCTAssertEqual(topic, "741f8902d339c4c16f33fa598a6598b63e5ed125d761374511b2e06562b033eb")
    }
}
