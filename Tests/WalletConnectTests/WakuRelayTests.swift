

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

fileprivate let testPayload =
"""
{
   "id":1630300527198334,
   "jsonrpc":"2.0",
   "method":"waku_subscription",
   "params":{
      "id":"0847f4e1dd19cf03a43dc7525f39896b630e9da33e4683c8efbc92ea671b5e07",
      "data":{
         "topic":"fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a",
         "message":"7b226964223a313633303330303532383030302c226a736f6e727063223a22322e30222c22726573756c74223a747275657d"
      }
   }
}
"""
