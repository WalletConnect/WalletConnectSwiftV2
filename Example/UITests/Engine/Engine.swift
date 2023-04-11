import Foundation
import XCTest

struct Engine {
    let routing = RoutingEngine()
    let dapp = DAppEngine()
    let wallet = WalletEngine()
    let safari = SafariEngine()

    /// Approve session request
    /// - Context:
    ///     - wallet opened
    ///     - approval request sent
    func approveSessionAndCheck() {
        wallet.approveButton.waitTap()

        XCTAssertTrue(wallet.sessionRow.waitExists())

        routing.activate(app: .dapp)

        XCTAssertTrue(dapp.accountRow.waitExists())
        XCTAssertTrue(dapp.disconnectButton.waitExists())
    }
}
