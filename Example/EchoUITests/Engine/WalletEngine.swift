import Foundation
import XCTest

struct WalletEngine {

    var instance: XCUIApplication {
        return App.wallet.instance
    }

    // Onboarding
    
    var getStartedButton: XCUIElement {
        instance.buttons["Get Started"]
    }
    
    // MainScreen

    var pasteURIButton: XCUIElement {
        instance.buttons["copy"]
    }

    var alert: XCUIElement {
        instance.descendants(matching: .any)["PasteUriView"]
    }

    var alertUriTextField: XCUIElement {
        alert.textFields.firstMatch
    }

    var alertConnectButton: XCUIElement {
        alert.buttons["Connect"]
    }

    var sessionRow: XCUIElement {
        instance.staticTexts["Swift Dapp"]
    }

    // Proposal

    var allowButton: XCUIElement {
        instance.buttons["Allow"]
    }

    var rejectButton: XCUIElement {
        instance.buttons["Reject"]
    }

    // SessionDetails

    var pingButton: XCUIElement {
        instance.buttons["Ping"]
    }

    var okButton: XCUIElement {
        instance.buttons["OK"]
    }

    var pingAlert: XCUIElement {
        instance.alerts.element.staticTexts["Received ping response"]
    }

    func swipeDismiss() {
        instance.swipeDown(velocity: .fast)
    }
}
