
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
        let predicate = NSPredicate(format: "label CONTAINS %@", text)

        let notification = springboard.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(notification.waitForExistence(timeout: 5))
        notification.tap()

//        waitForElementToAppear(object: notification)
    }

    func waitForElementToAppear(object: Any) {
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: object, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
}
