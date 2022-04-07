import XCTest
@testable import WalletConnect

final class PairingSequenceTests: XCTestCase {
    
    var referenceDate: Date!
    
    override func setUp() {
        referenceDate = Date()
        func getDate() -> Date { return referenceDate }
        PairingSequence.dateInitializer = getDate
    }
    
    override func tearDown() {
        PairingSequence.dateInitializer = Date.init
    }
    
    func testAbsoluteValues() {
        XCTAssertEqual(PairingSequence.timeToLiveInactive, 5 * .minute, "Inactive time-to-live is 5 minutes.")
        XCTAssertEqual(PairingSequence.timeToLiveActive, 30 * .day, "Active time-to-live is 30 days.")
    }
    
    func testInitInactiveFromTopic() {
        let pairing = PairingSequence(topic: "", selfMetadata: AppMetadata.stub())
        let inactiveExpiry = referenceDate.advanced(by: PairingSequence.timeToLiveInactive)
        XCTAssertFalse(pairing.isActive)
        XCTAssertEqual(pairing.expiryDate, inactiveExpiry)
    }
    
    func testInitInactiveFromURI() {
        let pairing = PairingSequence(uri: WalletConnectURI.stub())
        let inactiveExpiry = referenceDate.advanced(by: PairingSequence.timeToLiveInactive)
        XCTAssertFalse(pairing.isActive)
        XCTAssertEqual(pairing.expiryDate, inactiveExpiry)
    }
    
    func testExtend() {
        var pairing = PairingSequence(topic: "", selfMetadata: AppMetadata.stub())
        let activeExpiry = referenceDate.advanced(by: PairingSequence.timeToLiveActive)
        try? pairing.extend()
        XCTAssertEqual(pairing.expiryDate, activeExpiry)
    }
}
