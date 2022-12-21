//  Copyright © 2021 Compass. All rights reserved.

import XCTest

class PushNotificationTests: XCTestCase {
    let wallet = XCUIApplication(bundleIdentifier: "com.walletconnect.example")
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    func testPushNotification() {
        wallet.launch()

        sleep(1)

        // Launch springboard
        springboard.activate()


        let notification = springboard.otherElements["Notification"].descendants(matching: .any)["NotificationShortLookView"]
        XCTAssertTrue(notification.waitExists())

//        waitForElementToAppear(object: notification)
        notification.tap()
    }

    func waitForElementToAppear(object: Any) {
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: object, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
}
