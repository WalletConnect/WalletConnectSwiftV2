
import XCTest

class PushNotificationTests: XCTestCase {
    let wallet = XCUIApplication(bundleIdentifier: "com.walletconnect.example")
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    func testPushNotification() {
        wallet.launch()

        sleep(1)

        // Launch springboard
        springboard.activate()
        let text = "Is this working"

        let notification = springboard.otherElements["Notification"].descendants(matching: .any)["NotificationShortLookView"]
        XCTAssertTrue(notification.waitForExistence(timeout: 5))
        notification.tap()
    }
}
