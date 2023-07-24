import Foundation
import XCTest
import TestingUtils
@testable import WalletConnectNotify

class SubscriptionsAutoUpdaterTests: XCTestCase {
    var sut: SubscriptionsAutoUpdater!
    
    func testUpdateSubscriptionsIfNeeded() async {
        let subscriptions: [PushSubscription] = [
            PushSubscription.stub(topic: "topic1", expiry: Date().addingTimeInterval(60 * 60 * 24 * 20)),
            PushSubscription.stub(topic: "topic2", expiry: Date().addingTimeInterval(60 * 60 * 24 * 10)),
            PushSubscription.stub(topic: "topic3", expiry: Date().addingTimeInterval(60 * 60 * 24 * 30))
        ]

        let expectation = expectation(description: "update")

        let notifyUpdateRequester = MockNotifyUpdateRequester()
        let logger = ConsoleLoggerMock()
        let pushStorage = MockPushStoring(subscriptions: subscriptions)

        notifyUpdateRequester.completionHandler = {
            if notifyUpdateRequester.updatedTopics.contains("topic2") {
                expectation.fulfill()
            }
        }

        sut = SubscriptionsAutoUpdater(notifyUpdateRequester: notifyUpdateRequester,
                                     logger: logger,
                                     pushStorage: pushStorage)

        await waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(notifyUpdateRequester.updatedTopics, ["topic2"])
    }
}
