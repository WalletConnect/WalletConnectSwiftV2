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
}
