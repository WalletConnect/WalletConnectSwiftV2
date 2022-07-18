import WalletConnectUtils
import Foundation
import Combine
import XCTest
@testable import WalletConnectRelay

class IridiumRelayTests: XCTestCase {
    var iridiumRelay: RelayClient!
    var dispatcher: DispatcherMock!

    override func setUp() {
        dispatcher = DispatcherMock()
        let logger = ConsoleLogger()
        iridiumRelay = RelayClient(dispatcher: dispatcher, logger: logger, keyValueStorage: RuntimeKeyValueStorage())
    }

    override func tearDown() {
        iridiumRelay = nil
        dispatcher = nil
    }

    func testNotifyOnSubscriptionRequest() {
        let subscriptionExpectation = expectation(description: "notifies with encoded message on a iridium subscription event")
        let topic = "0987"
        let message = "qwerty"
        let subscriptionId = "sub-id"
        let subscriptionParams = RelayJSONRPC.SubscriptionParams(id: subscriptionId, data: RelayJSONRPC.SubscriptionData(topic: topic, message: message))
        let subscriptionRequest = JSONRPCRequest<RelayJSONRPC.SubscriptionParams>(id: 12345, method: RelayJSONRPC.Method.subscription.method, params: subscriptionParams)
        iridiumRelay.onMessage = { subscriptionTopic, subscriptionMessage in
            XCTAssertEqual(subscriptionMessage, message)
            XCTAssertEqual(subscriptionTopic, topic)
            subscriptionExpectation.fulfill()
        }
        dispatcher.onMessage?(try! subscriptionRequest.json())
        waitForExpectations(timeout: 0.001, handler: nil)
    }

    func testPublishRequestAcknowledge() {
        let acknowledgeExpectation = expectation(description: "completion with no error on iridium request acknowledge after publish")
        let requestId = iridiumRelay.publish(topic: "", payload: "{}", tag: 0, onNetworkAcknowledge: { error in
            acknowledgeExpectation.fulfill()
            XCTAssertNil(error)
        })
        let response = try! JSONRPCResponse<Bool>(id: requestId, result: true).json()
        dispatcher.onMessage?(response)
        waitForExpectations(timeout: 0.001, handler: nil)
    }

    func testUnsubscribeRequestAcknowledge() {
        let acknowledgeExpectation = expectation(description: "completion with no error on iridium request acknowledge after unsubscribe")
        let topic = "1234"
        iridiumRelay.subscriptions[topic] = ""
        let requestId = iridiumRelay.unsubscribe(topic: topic) { error in
            XCTAssertNil(error)
            acknowledgeExpectation.fulfill()
        }
        let response = try! JSONRPCResponse<Bool>(id: requestId!, result: true).json()
        dispatcher.onMessage?(response)
        waitForExpectations(timeout: 0.001, handler: nil)
    }

    func testSubscriptionRequestDeliveredOnce() {
        let expectation = expectation(description: "Request duplicate not delivered")
        let subscriptionParams = RelayJSONRPC.SubscriptionParams(id: "sub_id", data: RelayJSONRPC.SubscriptionData(topic: "topic", message: "message"))
        let subscriptionRequest = JSONRPCRequest<RelayJSONRPC.SubscriptionParams>(id: 12345, method: RelayJSONRPC.Method.subscription.method, params: subscriptionParams)
        iridiumRelay.onMessage = { _, _ in
            expectation.fulfill()
        }
        dispatcher.onMessage?(try! subscriptionRequest.json())
        dispatcher.onMessage?(try! subscriptionRequest.json())
        waitForExpectations(timeout: 0.001, handler: nil)
    }

    func testSendOnPublish() {
        iridiumRelay.publish(topic: "", payload: "", tag: 0, onNetworkAcknowledge: { _ in})
        XCTAssertTrue(dispatcher.sent)
    }

    func testSendOnSubscribe() {
        iridiumRelay.subscribe(topic: "") {_ in }
        XCTAssertTrue(dispatcher.sent)
    }

    func testSendOnUnsubscribe() {
        let topic = "123"
        iridiumRelay.subscriptions[topic] = ""
        iridiumRelay.unsubscribe(topic: topic) {_ in }
        XCTAssertTrue(dispatcher.sent)
    }
}
