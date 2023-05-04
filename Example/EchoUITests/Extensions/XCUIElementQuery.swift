import Foundation
import XCTest

extension XCUIElementQuery {
    
    func containing(_ text: String) -> XCUIElementQuery {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let elementQuery = self.containing(predicate)
        return elementQuery
    }
}
