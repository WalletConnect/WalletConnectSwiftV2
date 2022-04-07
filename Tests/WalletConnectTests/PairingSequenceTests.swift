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
        
    }
    
    func testInitInactiveFromTopic() {
        let pairing = PairingSequence.build("", selfMetadata: AppMetadata.stub())
        let inactiveExpiry = referenceDate.advanced(by: PairingSequence.timeToLiveInactive)
        XCTAssertFalse(pairing.isActive)
        XCTAssertEqual(pairing.expiryDate, inactiveExpiry)
    }
    
    func testInitInactiveFromURI() {
        let pairing = PairingSequence.createFromURI(WalletConnectURI.stub())
        let inactiveExpiry = referenceDate.advanced(by: PairingSequence.timeToLiveInactive)
        XCTAssertFalse(pairing.isActive)
        XCTAssertEqual(pairing.expiryDate, inactiveExpiry)
    }
}
