import Foundation
import XCTest
import TestingUtils
@testable import WalletConnectNotify

class SubscriptionWatcherTests: XCTestCase {

    var sut: SubscriptionWatcher!
    var mockRequester: MockNotifyWatchSubscriptionsRequester!
    var mockLogger: ConsoleLoggerMock!
    var mockNotificationCenter: MockNotificationCenter!

    override func setUp() {
        super.setUp()
        mockRequester = MockNotifyWatchSubscriptionsRequester()
        mockLogger = ConsoleLoggerMock()
        mockNotificationCenter = MockNotificationCenter()
        sut = SubscriptionWatcher(notifyWatchSubscriptionsRequester: mockRequester, logger: mockLogger, notificationCenter: mockNotificationCenter)
        let account = Account("eip155:1:0x1AAe9864337E821f2F86b5D27468C59AA333C877")!
        sut.debounceInterval = 0.0001
        sut.setAccount(account)
    }

    override func tearDown() {
        sut = nil
        mockRequester = nil
        mockLogger = nil
        mockNotificationCenter = nil
        super.tearDown()
    }

    func testWatchSubscriptions() {
        let expectation = XCTestExpectation(description: "Expect watchSubscriptions to be called")

        mockRequester.onWatchSubscriptions = {
            expectation.fulfill()
        }

        sut.watchSubscriptions()

        wait(for: [expectation], timeout: 0.5)
    }


    func testWatchAppLifecycleReactsToEnterForegroundNotification() {
        let setupExpectation = XCTestExpectation(description: "Expect setupTimer to be called on app enter foreground")
        let watchSubscriptionsExpectation = XCTestExpectation(description: "Expect watchSubscriptions to be called on app enter foreground")

        sut.onSetupTimer = {
            setupExpectation.fulfill()
        }

        mockRequester.onWatchSubscriptions = {
            watchSubscriptionsExpectation.fulfill()
        }

        mockNotificationCenter.post(name: UIApplication.willEnterForegroundNotification)

        wait(for: [setupExpectation, watchSubscriptionsExpectation], timeout: 0.5)
    }

    func testTimerTriggeringWatchSubscriptionsMultipleTimes() {
        sut.timerInterval = 0.0001
        sut.setupTimer()

        let expectation = XCTestExpectation(description: "Expect watchSubscriptions to be called multiple times")
        expectation.expectedFulfillmentCount = 3

        mockRequester.onWatchSubscriptions = {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.5)
    }
}
