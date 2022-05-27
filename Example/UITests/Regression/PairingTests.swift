import XCTest

class PairingTests: XCTestCase {
    
    private let engine: Engine = Engine()
    
    override class func setUp() {
        let engine = Engine()
        engine.routing.delete(app: .wallet)
        engine.routing.delete(app: .dapp)
    }
    
    func testPairingCreation() {
        engine.routing.open(app: .dapp)

        // Connect button doesn't work without it for some reasons
        engine.routing.wait(for: 2)

        engine.dapp.connectButton.tap()
        engine.dapp.newPairingButton.tap()
        engine.dapp.copyURIButton.tap()

        engine.routing.open(app: .wallet)

        XCTAssertFalse(engine.wallet.sessionRow.exists)

        engine.wallet.pasteURIButton.tap()
        engine.wallet.uriTextfield.typeText(UIPasteboard.general.string!)

        let uri = engine.wallet.uriTextfield.value as? String
        XCTAssertEqual(uri!.prefix(3), "wc:")
        XCTAssertEqual(uri!.suffix(20), "&relay-protocol=waku")

        engine.wallet.connectButton.tap()
        engine.wallet.approveButton.tap()

        XCTAssertTrue(engine.wallet.sessionRow.exists)
        
        engine.routing.open(app: .dapp)
        engine.dapp.accountRow.waitForAppearence()
        
        XCTAssertTrue(engine.dapp.accountRow.exists)
        XCTAssertTrue(engine.dapp.disconnectButton.exists)
    }
    
    func testPingResponse() {
        engine.routing.open(app: .dapp)
        engine.routing.open(app: .wallet)
        
        engine.wallet.sessionRow.tap()
        engine.wallet.pingButton.tap()
        
        engine.wallet.pingAlert.waitForAppearence()
        XCTAssertTrue(engine.wallet.pingAlert.exists)
    }
}
