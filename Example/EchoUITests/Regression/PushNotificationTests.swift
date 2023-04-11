
import XCTest

class PushNotificationTests: XCTestCase {

    private var engine: Engine!

    override func setUp() {
        engine = Engine()
//        engine.routing.launch(app: .wallet, clean: true)
//
//        engine.routing.launch(app: .dapp, clean: true)
        
    }
    
    func testPushNotification() {
        engine.routing.activate(app: .dapp)

        // TODO: Figure out why you need to wait here
//        engine.routing.wait(for: 3)

        // Initiate connection & copy URI from dApp
        engine.dapp.connectButton.waitTap()
        engine.dapp.newPairingButton.waitTap()
        engine.dapp.copyURIButton.waitTap()
        
        // Paste URI into Wallet & and allow connect
        engine.routing.activate(app: .wallet)
        allowPushNotificationsIfNeeded(app: engine.wallet.instance)
        engine.wallet.getStartedButton.waitTap()
        engine.wallet.pasteURIButton.waitTap()
        engine.wallet.alertUriTextField.pasteText(application: App.wallet.instance)
        engine.wallet.alertConnectButton.waitTap()
        engine.allowSessionAndCheck()

        //
        engine.dapp.accountRow.waitTap()
        engine.dapp.methodRow.waitTap()
        
        // Launch springboard
        engine.routing.springboard.activate()

        let notification = engine.routing.springboard.otherElements["Notification"].descendants(matching: .any)["NotificationShortLookView"]
        XCTAssertTrue(notification.waitExists())
        XCTAssertEqual(notification.label, "WALLETAPP, now, Signature required, You have a message to sign")
        notification.tap()
        
        engine.wallet.instance.waitForAppearence()
        XCTAssertTrue(engine.wallet.allowButton.waitExists())
    }
    
    private func allowPushNotificationsIfNeeded(app: XCUIApplication) {
        addUIInterruptionMonitor(withDescription: "Push Notification Monitor") { alerts -> Bool in
            if alerts.buttons["Allow"].exists {
                alerts.buttons["Allow"].tap()
            }
            
            return true
        }
        app.swipeUp()
    }
}

extension XCUIElement {
    

}

extension XCUIElementQuery {
    
    func containing(_ text: String) -> XCUIElementQuery {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let elementQuery = self.containing(predicate)
        return elementQuery
    }
}
