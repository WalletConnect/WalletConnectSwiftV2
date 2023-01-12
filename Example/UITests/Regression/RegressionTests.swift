import XCTest

class PairingTests: XCTestCase {
    private let engine: Engine = Engine()

    override class func setUp() {
        let engine: Engine = Engine()
        engine.routing.launch(app: .dapp, clean: true)
        engine.routing.launch(app: .wallet, clean: true)
    }

    /// Check pairing proposal approval via QR code or uri
    /// - TU001
    func test01PairingCreation() {
        engine.routing.activate(app: .dapp)

        // TODO: Figure out why you need to wait here
        engine.routing.wait(for: 3)

        engine.dapp.connectButton.waitTap()

        engine.dapp.newPairingButton.waitTap()
        engine.dapp.copyURIButton.waitTap()

        engine.routing.activate(app: .wallet)

        XCTAssertFalse(engine.wallet.sessionRow.waitExists())

        engine.wallet.pasteURIButton.waitTap()
        engine.wallet.pasteAndConnect.waitTap()

        engine.approveSessionAndCheck()
    }

    /// Check session ping on Wallet
    /// - TU002
    func test02PingResponse() {
        engine.routing.activate(app: .wallet)

        engine.wallet.sessionRow.waitTap()
        engine.wallet.pingButton.waitTap()

        XCTAssertTrue(engine.wallet.pingAlert.waitExists())

        engine.wallet.okButton.waitTap()
        engine.wallet.swipeDismiss()
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
