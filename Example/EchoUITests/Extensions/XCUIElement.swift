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

    func tapUntilOtherElementHittable(otherElement: XCUIElement, maxRetries: Int = 5) {
        var retry = 0
        while(!otherElement .isHittable && retry < maxRetries) {
            tap ()
            retry += 1
        }
    }
    
    func waitExists() -> Bool {
        waitForAppearence()
        return exists
    }
}
