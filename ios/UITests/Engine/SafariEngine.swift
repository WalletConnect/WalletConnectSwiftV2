import Foundation
import XCTest

struct SafariEngine {

    private var instance: XCUIApplication {
        return App.safari.instance
    }
}
