
import XCTest

class PushNotificationTests: XCTestCase {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    private let engine: Engine = Engine()

    override func setUp() {
        let engine: Engine = Engine()
        engine.routing.launch(app: .dapp, clean: true)
        engine.routing.launch(app: .wallet, clean: true)
        
        allowPushNotificationsIfNeeded(app: engine.wallet.instance)
    }
    
    func testPushNotification() {
            
        engine.routing.activate(app: .dapp)

        // TODO: Figure out why you need to wait here
        engine.routing.wait(for: 3)

        engine.dapp.connectButton.waitTap()

        engine.dapp.newPairingButton.waitTap()
        engine.dapp.copyURIButton.waitTap()
        
        engine.routing.activate(app: .wallet)

        engine.wallet.getStartedButton.waitTap()
        engine.wallet.pasteURIButton.waitTap()

        engine.wallet.alertUriTextField.pasteText(application: App.wallet.instance)
        engine.wallet.alertConnectButton.waitTap()

        engine.allowSessionAndCheck()

        engine.dapp.accountRow.waitTap()
        engine.dapp.methodRow.waitTap()
        
        
        // Launch springboard
        engine.routing.springboard.activate()

        let notification = springboard.otherElements["Notification"].descendants(matching: .any)["NotificationShortLookView"]
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
    func pasteText(application: XCUIApplication) {
        tap()
        doubleTap()
        application.menuItems.element(boundBy: 0).tap()
    }

}

extension XCUIElementQuery {
    
    func containing(_ text: String) -> XCUIElementQuery {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let elementQuery = self.containing(predicate)
        return elementQuery
    }
}
