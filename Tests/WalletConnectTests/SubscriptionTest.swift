
import Foundation
import XCTest
@testable import WalletConnect

class WCSubscriberTest: XCTestCase {
    var relay: MockedRelay!
    var subscriber: WCSubscriber!
    override func setUp() {
        relay = MockedRelay()
        subscriber = WCSubscriber(relay: relay)
    }

    override func tearDown() {
        relay = nil
        subscriber = nil
    }
    
    func testSetGetSubscription() {
        let topic = "1234"
        subscriber.setSubscription(topic: topic)
        XCTAssertNotNil(subscriber.getSubscription(topic: topic))
        XCTAssertTrue(relay.didCallSubscribe)
    }
    
    func testRemoveSubscription() {
        let topic = "1234"
        subscriber.setSubscription(topic: topic)
        subscriber.removeSubscription(topic: topic)
        XCTAssertNil(subscriber.getSubscription(topic: topic))
        XCTAssertTrue(relay.didCallUnsubscribe)
    }
}
