import Foundation
import XCTest

struct DAppEngine {

    private var instance: XCUIApplication {
        return App.dapp.instance
    }

    // Main screen

    var connectButton: XCUIElement {
        instance.buttons["Connect"]
    }

    // Accounts screen

    var accountRow: XCUIElement {
        instance.staticTexts["0xe5EeF1368781911d265fDB6946613dA61915a501"]
    }

    var disconnectButton: XCUIElement {
        instance.buttons["Disconnect"]
    }

    // Pairing screen

    var pairingRow: XCUIElement {
        instance.staticTexts["Example Wallet"]
    }

    var newPairingButton: XCUIElement {
        instance.buttons["New Pairing"]
    }

    var copyURIButton: XCUIElement {
        instance.buttons["Copy"]
    }
}
