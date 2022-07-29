import XCTest
import WalletConnectPairing
@testable import WalletConnectSign

final class WCPairingTests: XCTestCase {

    var referenceDate: Date!

    override func setUp() {
        referenceDate = Date()
        func getDate() -> Date { return referenceDate }
        WCPairing.dateInitializer = getDate
    }

    override func tearDown() {
        WCPairing.dateInitializer = Date.init
    }

    func testAbsoluteValues() {
        XCTAssertEqual(WCPairing.timeToLiveInactive, 5 * .minute, "Inactive time-to-live is 5 minutes.")
        XCTAssertEqual(WCPairing.timeToLiveActive, 30 * .day, "Active time-to-live is 30 days.")
    }

    func testInitInactiveFromTopic() {
        let pairing = WCPairing(topic: "")
        let inactiveExpiry = referenceDate.advanced(by: WCPairing.timeToLiveInactive)
        XCTAssertFalse(pairing.active)
        XCTAssertEqual(pairing.expiryDate, inactiveExpiry)
    }

    func testInitInactiveFromURI() {
        let pairing = WCPairing(uri: WalletConnectURI.stub())
        let inactiveExpiry = referenceDate.advanced(by: WCPairing.timeToLiveInactive)
        XCTAssertFalse(pairing.active)
        XCTAssertEqual(pairing.expiryDate, inactiveExpiry)
    }

    func testUpdateExpiry() {
        var pairing = WCPairing(topic: "")
        let activeExpiry = referenceDate.advanced(by: WCPairing.timeToLiveActive)
        try? pairing.updateExpiry()
        XCTAssertEqual(pairing.expiryDate, activeExpiry)
    }

    func testActivate() {
        var pairing = WCPairing(topic: "")
        let activeExpiry = referenceDate.advanced(by: WCPairing.timeToLiveActive)
        pairing.activate()
        XCTAssertTrue(pairing.active)
        XCTAssertEqual(pairing.expiryDate, activeExpiry)
    }
}
