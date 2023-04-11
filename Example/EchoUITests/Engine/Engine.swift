import Foundation
import XCTest

struct Engine {
    let routing = RoutingEngine()
    let dapp = DAppEngine()
    let wallet = WalletEngine()

    /// Approve session request
    /// - Context:
    ///     - wallet opened
    ///     - approval request sent
    func allowSessionAndCheck() {
        wallet.allowButton.waitTap()

        XCTAssertTrue(wallet.sessionRow.waitExists())

        routing.activate(app: .dapp)

        XCTAssertTrue(dapp.accountRow.waitExists())
        XCTAssertTrue(dapp.disconnectButton.waitExists())
    }
}
