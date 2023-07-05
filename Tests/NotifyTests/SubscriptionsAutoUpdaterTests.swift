import Foundation
import XCTest
import TestingUtils
@testable import WalletConnectPush

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


extension PushSubscription {
    static func stub(topic: String, expiry: Date) -> PushSubscription {
        let account = Account(chainIdentifier: "eip155:1", address: "0x15bca56b6e2728aec2532df9d436bd1600e86688")!
        let relay = RelayProtocolOptions.stub()
        let metadata = AppMetadata.stub()
        let symKey = "key1"

        return PushSubscription(
            topic: topic,
            account: account,
            relay: relay,
            metadata: metadata,
            scope: ["test": ScopeValue(description: "desc", enabled: true)],
            expiry: expiry,
            symKey: symKey
        )
    }
}


class MockNotifyUpdateRequester: NotifyUpdateRequesting {
    var updatedTopics: [String] = []
    var completionHandler: (() -> Void)?

    func update(topic: String, scope: Set<String>) async throws {
        updatedTopics.append(topic)
        completionHandler?()
    }
}



class MockPushStoring: PushStoring {
    var subscriptions: [PushSubscription]

    init(subscriptions: [PushSubscription]) {
        self.subscriptions = subscriptions
    }

    func getSubscriptions() -> [PushSubscription] {
        return subscriptions
    }

    func getSubscription(topic: String) -> PushSubscription? {
        return subscriptions.first { $0.topic == topic }
    }

    func setSubscription(_ subscription: PushSubscription) async throws {
        if let index = subscriptions.firstIndex(where: { $0.topic == subscription.topic }) {
            subscriptions[index] = subscription
        } else {
            subscriptions.append(subscription)
        }
    }

    func deleteSubscription(topic: String) async throws {
        subscriptions.removeAll(where: { $0.topic == topic })
    }
}
