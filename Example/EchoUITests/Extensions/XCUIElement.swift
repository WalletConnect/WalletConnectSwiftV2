import Foundation
import XCTest

extension XCUIElement {

    @discardableResult
    func waitForAppearence(timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) -> Bool {
        return waitForExistence(timeout: timeout)
    }

    func waitTap(file: StaticString = #file, line: UInt = #line) {
        waitForAppearence(file: file, line: line)
        tap()
    }

    func tapUntilOtherElementHittable(otherElement: XCUIElement, maxRetries: Int = 5) {
        var retry = 0
        while(!otherElement .isHittable && retry < maxRetries) {
            tap ()
            retry += 1
        }
    }
    
    func waitExists(file: StaticString = #file, line: UInt = #line) -> Bool {
        waitForAppearence(file: file, line: line)
        return exists
    }
}
