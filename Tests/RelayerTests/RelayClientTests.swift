import WalletConnectUtils
import Foundation
import Combine
import JSONRPC
import XCTest
@testable import WalletConnectRelay

final class RelayClientTests: XCTestCase {

    var sut: RelayClient!
    var dispatcher: DispatcherMock!

    override func setUp() {
        dispatcher = DispatcherMock()
        let logger = ConsoleLogger()
        sut = RelayClient(dispatcher: dispatcher, logger: logger, keyValueStorage: RuntimeKeyValueStorage())
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
        let subscription = Subscription(id: subscriptionId, topic: topic, message: message)
        let request = subscription.asRPCRequest()

        sut.onMessage = { subscriptionTopic, subscriptionMessage in
            XCTAssertEqual(subscriptionMessage, message)
            XCTAssertEqual(subscriptionTopic, topic)
            expectation.fulfill()
        }
        dispatcher.onMessage?(try! request.asJSONEncodedString())
        waitForExpectations(timeout: 0.001, handler: nil)
    }

    func testSubscribeRequestAcknowledge() {
        let acknowledgeExpectation = expectation(description: "")
        sut.subscribe(topic: "") { error in
            XCTAssertNil(error)
            acknowledgeExpectation.fulfill()
        }
        let request = dispatcher.getLastRequestSent()
        let response = RPCResponse(matchingRequest: request, result: "id")
        dispatcher.onMessage?(try! response.asJSONEncodedString())
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testPublishRequestAcknowledge() {
        let expectation = expectation(description: "Publish must callback on relay server acknowledgement")
        sut.publish(topic: "", payload: "{}", tag: 0) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        let request = dispatcher.getLastRequestSent()
        let response = RPCResponse(matchingRequest: request, result: true)
        dispatcher.onMessage?(try! response.asJSONEncodedString())
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testUnsubscribeRequestAcknowledge() {
        let expectation = expectation(description: "Unsubscribe must callback on relay server acknowledgement")
        let topic = String.randomTopic()
        sut.subscriptions[topic] = ""
        sut.unsubscribe(topic: topic) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        let request = dispatcher.getLastRequestSent()
        let response = RPCResponse(matchingRequest: request, result: true)
        dispatcher.onMessage?(try! response.asJSONEncodedString())
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testSubscriptionRequestDeliveredOnce() {
        let expectation = expectation(description: "Duplicate Subscription requests must notify only the first time")
        let request = Subscription.init(id: "sub_id", topic: "topic", message: "message").asRPCRequest()
        sut.onMessage = { _, _ in
            expectation.fulfill()
        }
        dispatcher.onMessage?(try! request.asJSONEncodedString())
        dispatcher.onMessage?(try! request.asJSONEncodedString())
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testSendOnPublish() {
        sut.publish(topic: "", payload: "", tag: 0, onNetworkAcknowledge: { _ in})
        XCTAssertTrue(dispatcher.sent)
    }

    func testSendOnSubscribe() {
        sut.subscribe(topic: "") {_ in }
        XCTAssertTrue(dispatcher.sent)
    }

    func testSendOnUnsubscribe() {
        let topic = "123"
        sut.subscriptions[topic] = ""
        sut.unsubscribe(topic: topic) {_ in }
        XCTAssertTrue(dispatcher.sent)
    }
}
