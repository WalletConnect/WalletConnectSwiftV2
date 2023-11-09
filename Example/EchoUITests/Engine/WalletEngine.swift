import Foundation
import XCTest

struct WalletEngine {

    var instance: XCUIApplication {
        return App.wallet.instance
    }

    // Onboarding
    
    var getStartedButton: XCUIElement {
        instance.buttons["Create new account"]
    }
    
    // MainScreen

    var allow: XCUIElement {
        instance.buttons["Allow"]
    }
    
    var copyURIButton: XCUIElement {
        instance.firstMatch.buttons.element(matching: .button, identifier: "copy")
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
