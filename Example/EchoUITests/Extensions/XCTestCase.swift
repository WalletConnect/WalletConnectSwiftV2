import Foundation
import XCTest

extension XCTestCase {
    
    func allowPushNotificationsIfNeeded(app: XCUIApplication) {
        let pnPermission = addUIInterruptionMonitor(withDescription: "Push Notification Monitor") { alerts -> Bool in
            if alerts.buttons["Allow"].exists {
                alerts.buttons["Allow"].tap()
            }
            
            return true
        }
        app.swipeUp()
        
        self.removeUIInterruptionMonitor(pnPermission)
    }
    
    func pasteText(element: XCUIElement, application: XCUIApplication, file: StaticString = #file, line: UInt = #line) {
        let pasteButton = application.menuItems["Paste"]
        // Getting the paste button to appear can be finicky as focus can differ between devices
        element.tapUntilOtherElementHittable(otherElement: pasteButton)
        pasteButton.tap()
    }
}
