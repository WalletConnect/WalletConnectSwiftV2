
//
//import Foundation
//import XCTest
//@testable import WalletConnect
//
//class WCSubscriberTest: XCTestCase {
//    var relay: MockedRelay!
//    var subscriber: WCSubscriber!
//    override func setUp() {
//        relay = MockedRelay()
//        subscriber = WCSubscriber(relay: relay)
//    }
//
//    override func tearDown() {
//        relay = nil
//        subscriber = nil
//    }
//    
//    func testSetGetSubscription() {
//        let topic = "1234"
//        subscriber.setSubscription(topic: topic)
//        XCTAssertNotNil(subscriber.getSubscription(topic: topic))
//        XCTAssertTrue(relay.didCallSubscribe)
//    }
//    
//    func testRemoveSubscription() {
//        let topic = "1234"
//        subscriber.setSubscription(topic: topic)
//        subscriber.removeSubscription(topic: topic)
//        XCTAssertNil(subscriber.getSubscription(topic: topic))
//        XCTAssertTrue(relay.didCallUnsubscribe)
//    }
//    
//    func testSubscriberPassesPayloadOnSubscribedEvent() {
//        let subscriptionExpectation = expectation(description: "onSubscription callback executed")
//        let topic = "1234"
//        let subscriptionId = "5853ad129f4753ca930c4a4b954d6d83cdcd7a4e63017548c2fddf829a3d8f2b"
//        relay.subscribeCompletionId = subscriptionId
//        subscriber.setSubscription(topic: topic)
//        subscriber.onRequestSubscription = { _ in
//            subscriptionExpectation.fulfill()
//        }
//        Thread.sleep(forTimeInterval: 0.01)
//        relay.sendSubscriptionPayloadOn(topic: topic, subscriptionId: subscriptionId)
//        waitForExpectations(timeout: 0.1, handler: nil)
//    }
//    
//    func testSubscriberNotPassesPayloadOnNotSubscribedEvent() {
//        let topic = "1234"
//        let subscribeCompletionId = "5853ad129f4753ca930c4a4b954d6d83cdcd7a4e63017548c2fddf829a3d8f2b"
//        relay.subscribeCompletionId = subscribeCompletionId
//        subscriber.setSubscription(topic: topic)
//        var onPayloadCalled = false
//        subscriber.onRequestSubscription = { _ in
//            onPayloadCalled = true
//        }
//        let payloadSubscriptionId = "dfddff4753ca930c4a4b954d6d83cdcd7a4e63017548c2fddf829a3d8f2b"
//        relay.sendSubscriptionPayloadOn(topic: topic, subscriptionId: payloadSubscriptionId)
//        XCTAssertFalse(onPayloadCalled)
//    }
//}
