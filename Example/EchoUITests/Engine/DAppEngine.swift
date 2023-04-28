import Foundation
import XCTest

struct DAppEngine {

    var instance: XCUIApplication {
        return App.dapp.instance
    }

    // Main screen

    var connectButton: XCUIElement {
        instance.buttons["Connect"]
    }

    // Accounts screen

    var accountRow: XCUIElement {
        instance.tables.cells.containing("0x").firstMatch
    }
    
    var methodRow: XCUIElement {
        instance.tables.cells.firstMatch
    }

    // Pairing screen

    var newPairingButton: XCUIElement {
        instance.buttons["New Pairing"]
    }

    var copyURIButton: XCUIElement {
        instance.buttons["Copy"]
    }
}
