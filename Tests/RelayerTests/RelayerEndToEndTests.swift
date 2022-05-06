
import Foundation
import Combine
import XCTest
import WalletConnectUtils
import TestingUtils
@testable import Relayer
import Starscream

final class RelayerEndToEndTests: XCTestCase {
    
    let relayHost = "relay.walletconnect.com"
    let projectId = "8ba9ee138960775e5231b70cc5ef1c3a"
    private var publishers = [AnyCancellable]()
    
    func makeRelayer() -> Relayer {
        let logger = ConsoleLogger()
        let url = Relayer.makeRelayUrl(host: relayHost, projectId: projectId)
        let socket = WebSocket(url: url)
        let dispatcher = Dispatcher(socket: socket, socketConnectionHandler: ManualSocketConnectionHandler(socket: socket))
        return Relayer(dispatcher: dispatcher, logger: logger, keyValueStorage: RuntimeKeyValueStorage())
    }
    
    func testSubscribe() {
        let relayer = makeRelayer()
        try! relayer.connect()
        let subscribeExpectation = expectation(description: "subscribe call succeeds")
        subscribeExpectation.assertForOverFulfill = true
        relayer.socketConnectionStatusPublisher.sink { status in
            if status == .connected {
                relayer.subscribe(topic: "qwerty") { error in
                    XCTAssertNil(error)
                    subscribeExpectation.fulfill()
                }
            }
        }.store(in: &publishers)
        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }
    
    func testEndToEndPayload() {
        let relayA = makeRelayer()
        let relayB = makeRelayer()
        try! relayA.connect()
        try! relayB.connect()

        let randomTopic = String.randomTopic()
        let payloadA = "A"
        let payloadB = "B"
        var subscriptionATopic: String!
        var subscriptionBTopic: String!
        var subscriptionAPayload: String!
        var subscriptionBPayload: String!

        let expectationA = expectation(description: "publish payloads send and receive successfuly")
        let expectationB = expectation(description: "publish payloads send and receive successfuly")
        
        expectationA.assertForOverFulfill = false
        expectationB.assertForOverFulfill = false

        relayA.onMessage = { topic, payload in
            (subscriptionATopic, subscriptionAPayload) = (topic, payload)
            expectationA.fulfill()
        }
        relayB.onMessage = { topic, payload in
            (subscriptionBTopic, subscriptionBPayload) = (topic, payload)
            expectationB.fulfill()
        }
        relayA.socketConnectionStatusPublisher.sink {  _ in
            relayA.publish(topic: randomTopic, payload: payloadA, onNetworkAcknowledge: { error in
                XCTAssertNil(error)
            })
            relayA.subscribe(topic: randomTopic) { error in
                XCTAssertNil(error)
            }
        }.store(in: &publishers)
        relayB.socketConnectionStatusPublisher.sink {  _ in
            relayB.publish(topic: randomTopic, payload: payloadB, onNetworkAcknowledge: { error in
                XCTAssertNil(error)
            })
            relayB.subscribe(topic: randomTopic) { error in
                XCTAssertNil(error)
            }
        }.store(in: &publishers)

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertEqual(subscriptionATopic, randomTopic)
        XCTAssertEqual(subscriptionBTopic, randomTopic)
        
        //TODO - uncomment lines when request rebound is resolved
//        XCTAssertEqual(subscriptionBPayload, payloadA)
//        XCTAssertEqual(subscriptionAPayload, payloadB)
    }
}
