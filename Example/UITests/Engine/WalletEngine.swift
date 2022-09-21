import Foundation
import XCTest

struct WalletEngine {

    private var instance: XCUIApplication {
        return App.wallet.instance
    }

    // MainScreen

    var pasteURIButton: XCUIElement {
        instance.buttons["Paste URI"]
    }

    var alert: XCUIElement {
        instance.alerts["Paste URI"]
    }

    var uriTextfield: XCUIElement {
        alert.textFields.firstMatch
    }

    var pasteAndConnect: XCUIElement {
        alert.buttons["Paste and Connect"]
    }

    var sessionRow: XCUIElement {
        instance.staticTexts["Swift Dapp"]
    }

    // Proposal

    var approveButton: XCUIElement {
        instance.buttons["Approve"]
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
