import XCTest

class PushNotificationTests: XCTestCase {

    private var engine: Engine!

    override func setUp() {
        super.setUp()
        engine = Engine()
        engine.routing.launch(app: .wallet, clean: true)
        engine.routing.launch(app: .dapp, clean: true)
    }
    
    func testPushNotification() {
        
        // Initiate connection & copy URI from dApp
        engine.routing.activate(app: .dapp)
        engine.dapp.connectButton.wait(until: \.exists).tap()
        engine.dapp.newPairingButton.wait(until: \.exists).tap()
        
        // Relies on existence of invisible label with uri in Dapp
        let uri = engine.dapp.instance.staticTexts.containing("wc:").firstMatch.label
        
        engine.dapp.copyURIButton.wait(until: \.exists).tap()
        
        // Paste URI into Wallet & and allow connect
        engine.routing.activate(app: .wallet)
        
        allowPushNotificationsIfNeeded(app: engine.wallet.instance)
        
        engine.wallet.getStartedButton.wait(until: \.exists).tap()
        engine.wallet.pasteURIButton.wait(until: \.exists).tap()
        
        engine.wallet.alertUriTextField.wait(until: \.exists).tap()
        engine.wallet.alertUriTextField.typeText(uri)
        engine.wallet.alertConnectButton.wait(until: \.exists).tap()
    
        // Allow session
        engine.wallet.allowButton.wait(until: \.exists, timeout: 15, message: "No session dialog appeared").tap()
    
        // Trigger PN
        engine.routing.activate(app: .dapp)
        engine.dapp.accountRow.wait(until: \.exists, timeout: 15).tap()
        engine.dapp.methodRow.wait(until: \.exists).tap()
        
        // Launch springboard
        engine.routing.activate(app: .springboard)
        
        // Assert notification
        let notification = engine.routing.springboard.otherElements.descendants(matching: .any)["NotificationShortLookView"]
        notification
            .wait(until: \.exists, timeout: 15)
            .tap()
        
        engine.wallet.instance.wait(until: \.exists)
    }
}
