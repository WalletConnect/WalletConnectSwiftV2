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

    override func setUp() {
        dispatcher = DispatcherMock()
        let logger = ConsoleLogger()
        let clientIdStorage = ClientIdStorageMock()
        sut = RelayClient(dispatcher: dispatcher, logger: logger, keyValueStorage: RuntimeKeyValueStorage(), clientIdStorage: clientIdStorage)
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

        sut.messagePublisher.sink { (subscriptionTopic, subscriptionMessage, _) in
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

    func testPublishRequest() async {
        try? await sut.publish(topic: "", payload: "{}", tag: 0, prompt: false, ttl: 60)
        let request = dispatcher.getLastRequestSent()
        XCTAssertNotNil(request)
    }

    func testUnsubscribeRequest() {
        let topic = String.randomTopic()
        sut.subscriptions[topic] = ""
        sut.unsubscribe(topic: topic) { error in
            XCTAssertNil(error)
        }
        let request = dispatcher.getLastRequestSent()
        XCTAssertNotNil(request)
    }

    func testSubscriptionRequestDeliveredOnce() {
        let expectation = expectation(description: "Duplicate Subscription requests must notify only the first time")
        let request = Subscription.init(id: "sub_id", topic: "topic", message: "message").asRPCRequest()
        
        sut.messagePublisher.sink { (_, _, _) in
            expectation.fulfill()
        }.store(in: &publishers)

        dispatcher.onMessage?(try! request.asJSONEncodedString())
        dispatcher.onMessage?(try! request.asJSONEncodedString())
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testSendOnPublish() async {
        try? await sut.publish(topic: "", payload: "", tag: 0, prompt: false, ttl: 60)
        XCTAssertTrue(dispatcher.sent)
    }

    func testSendOnSubscribe() async {
        try? await sut.subscribe(topic: "")
        XCTAssertTrue(dispatcher.sent)
    }

    func testSendOnUnsubscribe() {
        let topic = "123"
        sut.subscriptions[topic] = ""
        sut.unsubscribe(topic: topic) {_ in }
        XCTAssertTrue(dispatcher.sent)
    }
}
