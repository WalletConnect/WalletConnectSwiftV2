
import Foundation
import Combine
import XCTest
import WalletConnectUtils
import TestingUtils
@testable import Relayer

final class RelayTests: XCTestCase {
    
    let url = URL(string: "wss://staging.walletconnect.org")!
    private var publishers = [AnyCancellable]()
    
    func makeRelayer() -> WakuNetworkRelay {
        let logger = ConsoleLogger()
        let dispatcher = Dispatcher(url: url)
        return WakuNetworkRelay(transport: dispatcher, logger: logger)
    }
    
    func testSubscribe() {
        let relayer = makeRelayer()
        let subscribeExpectation = expectation(description: "subscribe call succeeds")
        relayer.subscribe(topic: "qwerty") { error in
            XCTAssertNil(error)
            subscribeExpectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }
    
    func testEndToEndPayload() {
        let relayA = makeRelayer()
        let relayB = makeRelayer()

        let randomTopic = String.randomTopic()
        let payloadA = "A"
        let payloadB = "B"
        var subscriptionATopic: String!
        var subscriptionBTopic: String!
        var subscriptionAPayload: String!
        var subscriptionBPayload: String!

        let expectation = expectation(description: "publish payloads send and receive successfuly")
        expectation.expectedFulfillmentCount = 2
        
        relayA.onMessage = { topic, payload in
            (subscriptionATopic, subscriptionAPayload) = (topic, payload)
            expectation.fulfill()
        }
        relayB.onMessage = { topic, payload in
            (subscriptionBTopic, subscriptionBPayload) = (topic, payload)
            expectation.fulfill()
        }
        relayA.publish(topic: randomTopic, payload: payloadA) { error in
            XCTAssertNil(error)
        }
        relayB.publish(topic: randomTopic, payload: payloadB) { error in
            XCTAssertNil(error)
        }
        relayA.subscribe(topic: randomTopic) { error in
            XCTAssertNil(error)
        }
        relayB.subscribe(topic: randomTopic) { error in
            XCTAssertNil(error)
        }
        
        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertEqual(subscriptionATopic, randomTopic)
        XCTAssertEqual(subscriptionBTopic, randomTopic)
        XCTAssertEqual(subscriptionBPayload, payloadA)
        XCTAssertEqual(subscriptionAPayload, payloadB)
    }
}
