import Foundation
import XCTest

extension XCUIElement {
    
    @discardableResult
    func waitForDisappearance(timeout: TimeInterval = 3) -> Bool {
        return XCTContext.runActivity(named: "Waiting \(timeout)s for \(self) to disappear") { _ in
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: self
            )
            let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
            switch result {
            case .completed:
                return true
            default:
                return !exists
            }
        }
    }
    
    @discardableResult
    func waitForAppearence(timeout: TimeInterval = 5) -> Bool {
        return waitForExistence(timeout: timeout)
    }
    
    func tapUntilElementHittable(maxRetries: Int = 3) {
        var retries = 0
        while (!isHittable && retries < maxRetries) {
            retries += 1
            tap()
        }
    }
}
