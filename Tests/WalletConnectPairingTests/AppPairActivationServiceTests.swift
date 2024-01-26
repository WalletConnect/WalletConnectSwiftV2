import XCTest
@testable import WalletConnectPairing
@testable import TestingUtils
import WalletConnectUtils

final class AppPairActivationServiceTests: XCTestCase {

    var service: AppPairActivationService!
    var storageMock: WCPairingStorage!
    var logger: ConsoleLogger!

    override func setUp() {
        storageMock = WCPairingStorageMock()
        logger = ConsoleLogger()
        service = AppPairActivationService(pairingStorage: storageMock, logger: logger)
    }

    override func tearDown() {
        storageMock = nil
        logger = nil
        service = nil
    }

    func testActivate() {
        let pairing = WCPairing(uri: WalletConnectURI.stub())
        let topic = pairing.topic
        let date = pairing.expiryDate

        storageMock.setPairing(pairing)

        XCTAssertFalse(pairing.active)
        XCTAssertNil(pairing.peerMetadata)

        service.activate(for: topic, peerMetadata: .stub())

        let activated = storageMock.getPairing(forTopic: topic)!

        XCTAssertTrue(activated.active)
        XCTAssertNotNil(activated.peerMetadata)
        XCTAssertTrue(activated.expiryDate > date)
    }
}
