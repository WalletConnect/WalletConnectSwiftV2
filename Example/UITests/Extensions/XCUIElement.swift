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

    func waitTypeText(_ text: String, file: StaticString = #file, line: UInt = #line) {
        waitForAppearence(file: file, line: line)
        typeText(text)
    }

    func waitExists(file: StaticString = #file, line: UInt = #line) -> Bool {
        waitForAppearence(file: file, line: line)
        return exists
    }
}
