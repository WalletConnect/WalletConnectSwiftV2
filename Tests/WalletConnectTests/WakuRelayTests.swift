

import Foundation
import Combine
import XCTest
@testable import WalletConnect

class WakuRelayTests: XCTestCase {
    var wakuRelay: WakuNetworkRelay!
    var transport: MockedJSONRPCTransport!

    override func setUp() {
        transport = MockedJSONRPCTransport()
        let logger = MuteLogger()
        wakuRelay = WakuNetworkRelay(transport: transport, logger: logger)
    }

    override func tearDown() {
        wakuRelay = nil
        transport = nil
    }
    
    func testNotifyOnSubscriptionRequest() {
        let subscriptionExpectation = expectation(description: "notifies with encoded message on a waku subscription event")
        let topic = "0987"
        let message = "qwerty"
        let subscriptionId = "sub-id"
        let subscriptionParams = RelayJSONRPC.SubscriptionParams(id: subscriptionId, data: RelayJSONRPC.SubscriptionData(topic: topic, message: message))
        let subscriptionRequest = JSONRPCRequest<RelayJSONRPC.SubscriptionParams>(id: 12345, method: RelayJSONRPC.Method.subscription.rawValue, params: subscriptionParams)
        wakuRelay.onMessage = { subscriptionTopic, subscriptionMessage in
            XCTAssertEqual(subscriptionMessage, message)
            XCTAssertEqual(subscriptionTopic, topic)
            subscriptionExpectation.fulfill()
        }
        transport.onMessage?(try! subscriptionRequest.json())
        waitForExpectations(timeout: 0.001, handler: nil)
    }
    
    func testCompletionOnSubscribe() {
        let subscribeExpectation = expectation(description: "subscribe completes with no error")
        let topic = "0987"
        let requestId = wakuRelay.subscribe(topic: topic) { error in
            XCTAssertNil(error)
            subscribeExpectation.fulfill()
        }
        let subscriptionId = "sub-id"
        let subscribeResponse = JSONRPCResponse<String>(id: requestId, result: subscriptionId)
        transport.onMessage?(try! subscribeResponse.json())
        waitForExpectations(timeout: 0.001, handler: nil)
    }
    
    func testPublishRequestAcknowledge() {
        let acknowledgeExpectation = expectation(description: "completion with no error on waku request acknowledge after publish")
        let requestId = wakuRelay.publish(topic: "", payload: "{}") { error in
            acknowledgeExpectation.fulfill()
            XCTAssertNil(error)
        }
        let response = try! JSONRPCResponse<Bool>(id: requestId, result: true).json()
        transport.onMessage?(response)
        waitForExpectations(timeout: 0.001, handler: nil)
    }
    
    func testUnsubscribeRequestAcknowledge() {
        let acknowledgeExpectation = expectation(description: "completion with no error on waku request acknowledge after unsubscribe")
        let topic = "1234"
        wakuRelay.subscriptions[topic] = ""
        let requestId = wakuRelay.unsubscribe(topic: topic) { error in
            XCTAssertNil(error)
            acknowledgeExpectation.fulfill()
        }
        let response = try! JSONRPCResponse<Bool>(id: requestId!, result: true).json()
        transport.onMessage?(response)
        waitForExpectations(timeout: 0.001, handler: nil)
    }
    
    func testSendOnPublish() {
        wakuRelay.publish(topic: "", payload: "") {_ in }
        XCTAssertTrue(transport.sent)
    }
    
    func testSendOnSubscribe() {
        wakuRelay.subscribe(topic: "") {_ in }
        XCTAssertTrue(transport.sent)
    }
    
    func testSendOnUnsubscribe() {
        let topic = "123"
        wakuRelay.subscriptions[topic] = ""
        wakuRelay.unsubscribe(topic: topic) {_ in }
        XCTAssertTrue(transport.sent)
    }
}

