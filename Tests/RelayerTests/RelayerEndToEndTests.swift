
import Foundation
import Combine
import XCTest
import WalletConnectUtils
@testable import Relayer

final class RelayTests: XCTestCase {
    
    let url = URL(string: "wss://staging.walletconnect.org")!
    private var publishers = [AnyCancellable]()
    let defaultTimeout: TimeInterval = 2.0
    
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

        let randomTopic = "String.randomTopic()"
        let payload = "payload"

        let expectation = expectation(description: "publish payloads send and receive successfuly")
        expectation.expectedFulfillmentCount = 2
        
        relayA.onMessage = { topic, message in
            XCTAssertEqual(randomTopic, topic)
            expectation.fulfill()
        }
        
        relayB.onMessage = { topic, message in
            XCTAssertEqual(randomTopic, topic)
            expectation.fulfill()
        }
        
        [relayA, relayB].forEach { relay in
            relay.subscribe(topic: randomTopic) { error in
                XCTAssertNil(error)
            }
        }
        
        relayA.publish(topic: randomTopic, payload: payload) { error in
            XCTAssertNil(error)
        }
        relayB.publish(topic: randomTopic, payload: payload) { error in
            XCTAssertNil(error)
        }

        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }
}
