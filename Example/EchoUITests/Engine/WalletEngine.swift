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

    var alertUriTextField: XCUIElement {
        instance.textFields["wc://a13aef..."]
    }

    var alertConnectButton: XCUIElement {
        instance.buttons["Connect"]
    }

    var sessionRow: XCUIElement {
        instance.staticTexts["Swift Dapp"]
    }

    // Proposal

    var allowButton: XCUIElement {
        instance.buttons["Allow"]
    }
}
