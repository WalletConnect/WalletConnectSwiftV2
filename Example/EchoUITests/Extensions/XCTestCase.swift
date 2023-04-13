import Foundation
import XCTest

extension XCTestCase {
    
//    func waitTap(element: XCUIElement) {
//        let expectation = expectation(
//            for: NSPredicate(format: "exists == true"),
//            evaluatedWith: element
//        ) {
//            element.tap()
//            return 
//        }
//
//        let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
//
//        XCTAssertEqual(result, .completed)
//    }
    
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
        pasteButton
            .wait(until: \.exists)
            .wait(until: \.isHittable)
            .tap()
    }
}
