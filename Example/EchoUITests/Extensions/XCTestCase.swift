import Foundation
import XCTest

extension XCTestCase {

    func allowPushNotificationsIfNeeded(app: XCUIApplication) {
        /** iOS 17 bug: https://developer.apple.com/forums/thread/737880
        let pnPermission = addUIInterruptionMonitor(withDescription: "Push Notification Monitor") { alerts -> Bool in
            if alerts.buttons["Allow"].exists {
                alerts.buttons["Allow"].tap()
            }
            return true
        }
        app.swipeUp()
        
        self.removeUIInterruptionMonitor(pnPermission)
        */
        
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.buttons["Allow"].tap()
    }
}
