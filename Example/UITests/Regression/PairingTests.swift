import XCTest

class PairingTests: XCTestCase {
    
    private let engine: Engine = Engine()
    
    override class func setUp() {
        let engine = Engine()
        engine.routing.delete(app: .wallet)
        engine.routing.delete(app: .dapp)
    }
    
    override func setUp() {
        engine.routing.launch(app: .dapp)
        engine.routing.launch(app: .wallet)
    }

    /// Check pairing proposal approval via QR code or uri
    /// - TU001
    func test01PairingCreation() {
        engine.routing.activate(app: .dapp)

        // TODO: Figure out why you need to wait here
        engine.routing.wait(for: 2)

        engine.dapp.connectButton.waitTap()

        engine.dapp.newPairingButton.waitTap()
        engine.dapp.copyURIButton.waitTap()

        engine.routing.activate(app: .wallet)

        XCTAssertFalse(engine.wallet.sessionRow.waitExists())

        engine.wallet.pasteURIButton.waitTap()
        engine.wallet.uriTextfield.waitTypeText(UIPasteboard.general.string!)

        let uri = engine.wallet.uriTextfield.value as? String
        XCTAssertEqual(uri!.prefix(3), "wc:")
        XCTAssertEqual(uri!.suffix(20), "&relay-protocol=waku")

        engine.wallet.connectButton.waitTap()

        engine.approveSessionAndCheck()
    }
    
    /// Check session ping on Wallet
    /// - TU002
    func test02PingResponse() {
        engine.routing.activate(app: .wallet)
        
        engine.wallet.sessionRow.waitTap()
        engine.wallet.pingButton.waitTap()
        
        XCTAssertTrue(engine.wallet.pingAlert.waitExists())
    }
    
    /// Approve session on existing pairing
    /// - TU004
    func test04ApproveSessionExistingPairing() {
        engine.routing.activate(app: .dapp)

        engine.dapp.disconnectButton.waitTap()
        engine.dapp.connectButton.waitTap()
        engine.dapp.pairingRow.waitTap()
        
        // TODO: Figure out why you need to wait here
        engine.routing.wait(for: 2)
        
        engine.approveSessionAndCheck()
    }
}
