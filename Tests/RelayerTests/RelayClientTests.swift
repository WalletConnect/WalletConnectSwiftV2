import WalletConnectUtils
import Foundation
import Combine
import JSONRPC
import XCTest
@testable import WalletConnectRelay

final class RelayClientTests: XCTestCase {

    var sut: RelayClient!
    var dispatcher: DispatcherMock!
    var publishers = Set<AnyCancellable>()
    var subscriptionsTracker: SubscriptionsTrackerMock!

    override func setUp() {
        dispatcher = DispatcherMock()
        let logger = ConsoleLogger()
        let clientIdStorage = ClientIdStorageMock()
        let rpcHistory = RPCHistoryFactory.createForRelay(keyValueStorage: RuntimeKeyValueStorage())
        subscriptionsTracker = SubscriptionsTrackerMock()
        sut = RelayClient(dispatcher: dispatcher, logger: logger, rpcHistory: rpcHistory, clientIdStorage: clientIdStorage, subscriptionsTracker: subscriptionsTracker)
    }

    override func tearDown() {
        sut = nil
        dispatcher = nil
    }

    func testNotifyOnSubscriptionRequest() {
        let expectation = expectation(description: "Relay must notify listener on a Subscription request")
        let topic = "0987"
        let message = "qwerty"
        let subscriptionId = "sub-id"
        let subscription = Subscription(id: subscriptionId, topic: topic, message: message, attestation: nil)
        let request = subscription.asRPCRequest()

        sut.messagePublisher.sink { (subscriptionTopic, subscriptionMessage, _, _) in
            XCTAssertEqual(subscriptionMessage, message)
            XCTAssertEqual(subscriptionTopic, topic)
            expectation.fulfill()
        }.store(in: &publishers)

        dispatcher.onMessage?(try! request.asJSONEncodedString())
        waitForExpectations(timeout: 0.001, handler: nil)
    }

    func testSubscribeRequest() async {
        try? await sut.subscribe(topic: "")
        let request = dispatcher.getLastRequestSent()
        XCTAssertNotNil(request)
    }

    func testUnsubscribeRequest() {
        let topic = String.randomTopic()
        subscriptionsTracker.setSubscription(for: topic, id: "")
        sut.unsubscribe(topic: topic) { error in
            XCTAssertNil(error)
        }
        let request = dispatcher.getLastRequestSent()
        XCTAssertNotNil(request)
    }

    func testSubscriptionRequestDeliveredOnce() {
        let expectation = expectation(description: "Duplicate Subscription requests must notify only the first time")
        let request = Subscription.init(id: "sub_id", topic: "topic", message: "message").asRPCRequest()
        
        sut.messagePublisher.sink { (_, _, _, _) in
            expectation.fulfill()
        }.store(in: &publishers)

        dispatcher.onMessage?(try! request.asJSONEncodedString())
        dispatcher.onMessage?(try! request.asJSONEncodedString())
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testSendOnSubscribe() async {
        try? await sut.subscribe(topic: "")
        XCTAssertTrue(dispatcher.sent)
    }

    func testSendOnUnsubscribe() {
        let topic = "123"
        subscriptionsTracker.setSubscription(for: topic, id: "")
        sut.unsubscribe(topic: topic) {_ in }
        XCTAssertTrue(dispatcher.sent)
    }
}
