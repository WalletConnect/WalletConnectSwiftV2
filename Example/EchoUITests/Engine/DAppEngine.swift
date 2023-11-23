import Foundation
import XCTest

struct DAppEngine {

    var instance: XCUIApplication {
        return App.dapp.instance
    }

    // Main screen

    var connectButton: XCUIElement {
        instance.buttons["Connect with Sign API"]
    }

    // Accounts screen

    var accountRow: XCUIElement {
        instance.buttons.containing("0x").firstMatch
    }
    
    var methodRow: XCUIElement {
        instance.firstMatch.buttons.element(matching: .button, identifier: "method-0")
    }

    // Pairing screen

    var newPairingButton: XCUIElement {
        instance.buttons["New Pairing"]
    }

    var copyURIButton: XCUIElement {
        instance.buttons["Copy link"]
    }
}
