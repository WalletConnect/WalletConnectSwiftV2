import XCTest
@testable import WalletConnectPairing
@testable import WalletConnectUtils
@testable import WalletConnectUtils

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

    func testUpdateExpiryForTopic() {
        var pairing = WCPairing(topic: "")
        let activeExpiry = referenceDate.advanced(by: WCPairing.timeToLiveActive)
        try? pairing.updateExpiry()
        XCTAssertEqual(pairing.expiryDate, activeExpiry)
    }

    func testUpdateExpiryForUri() {
        var pairing = WCPairing(uri: WalletConnectURI.stub())
        let activeExpiry = referenceDate.advanced(by: WCPairing.timeToLiveActive)
        try? pairing.updateExpiry()
        XCTAssertEqual(pairing.expiryDate, activeExpiry)
    }

    func testActivateTopic() {
        var pairing = WCPairing(topic: "")
        let activeExpiry = referenceDate.advanced(by: WCPairing.timeToLiveActive)
        XCTAssertFalse(pairing.active)
        pairing.activate()
        XCTAssertTrue(pairing.active)
        XCTAssertEqual(pairing.expiryDate, activeExpiry)
    }

    func testActivateURI() {
        var pairing = WCPairing(uri: WalletConnectURI.stub())
        let activeExpiry = referenceDate.advanced(by: WCPairing.timeToLiveActive)
        XCTAssertFalse(pairing.active)
        pairing.activate()
        XCTAssertTrue(pairing.active)
        XCTAssertEqual(pairing.expiryDate, activeExpiry)
    }

    func testUpdateExpiryWhenValueIsGreaterThanMax() {
        var pairing = WCPairing(topic: "", relay: .stub(), peerMetadata: .stub(), expiryDate: referenceDate)
        XCTAssertThrowsError(try pairing.updateExpiry(40 * .day)) { error in
            XCTAssertEqual(error as! WCPairing.Errors, WCPairing.Errors.invalidUpdateExpiryValue)
        }
    }

    func testUpdateExpiryWhenNewExpiryDateIsLessThanExpiryDate() {
        let expiryDate = referenceDate.advanced(by: 40 * .day)
        var pairing = WCPairing(topic: "", relay: .stub(), peerMetadata: .stub(), expiryDate: expiryDate)
        XCTAssertThrowsError(try pairing.updateExpiry(10 * .minute)) { error in
            XCTAssertEqual(error as! WCPairing.Errors, WCPairing.Errors.invalidUpdateExpiryValue)
        }
    }

    func testActivateWhenCanUpdateExpiry() {
        var pairing = WCPairing(topic: "", relay: .stub(), peerMetadata: .stub(), expiryDate: referenceDate)
        XCTAssertFalse(pairing.active)
        pairing.activate()
        XCTAssertTrue(pairing.active)
        XCTAssertEqual(referenceDate.advanced(by: 30 * .day), pairing.expiryDate)
    }

    func testActivateWhenUpdateExpiryIsInvalid() {
        let expiryDate = referenceDate.advanced(by: 40 * .day)
        var pairing = WCPairing(topic: "", relay: .stub(), peerMetadata: .stub(), expiryDate: expiryDate)
        XCTAssertFalse(pairing.active)
        pairing.activate()
        XCTAssertTrue(pairing.active)
        XCTAssertEqual(expiryDate, pairing.expiryDate)
    }
}
