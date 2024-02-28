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
    }

    override func tearDown() {
        sut = nil
        mockRequester = nil
        mockLogger = nil
        mockNotificationCenter = nil
        super.tearDown()
    }

    func testWatchSubscriptions() async throws {
        let expectation = XCTestExpectation(description: "Expect watchSubscriptions to be called")

        mockRequester.onWatchSubscriptions = {
            expectation.fulfill()
        }

        try await sut.start()

        await fulfillment(of: [expectation], timeout: 0.5)
    }


    func testWatchAppLifecycleReactsToEnterForegroundNotification() async throws  {
        let watchSubscriptionsExpectation = XCTestExpectation(description: "Expect watchSubscriptions to be called on app enter foreground")
        watchSubscriptionsExpectation.expectedFulfillmentCount = 2

        mockRequester.onWatchSubscriptions = {
            watchSubscriptionsExpectation.fulfill()
        }

        try await sut.start()

        await mockNotificationCenter.post(name: UIApplication.willEnterForegroundNotification)

        await fulfillment(of: [watchSubscriptionsExpectation], timeout: 0.5)
    }

    func testTimerTriggeringWatchSubscriptionsMultipleTimes() async throws  {
        sut.timerInterval = 0.0001

        let expectation = XCTestExpectation(description: "Expect watchSubscriptions to be called multiple times")
        expectation.expectedFulfillmentCount = 3

        mockRequester.onWatchSubscriptions = {
            expectation.fulfill()
        }

        try await sut.start()

        wait(for: [expectation], timeout: 0.5)
    }
}
