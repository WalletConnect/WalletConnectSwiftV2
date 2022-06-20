import Foundation
import XCTest

extension XCUIElement {

    @discardableResult
    func waitForAppearence(timeout: TimeInterval = 5) -> Bool {
        return waitForExistence(timeout: timeout)
    }

    func waitTap() {
        waitForAppearence()
        tap()
    }

    func waitTypeText(_ text: String) {
        waitForAppearence()
        typeText(text)
    }

    func waitExists() -> Bool {
        waitForAppearence()
        return exists
    }
}
