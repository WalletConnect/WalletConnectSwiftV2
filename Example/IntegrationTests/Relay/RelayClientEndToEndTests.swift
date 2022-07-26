import Foundation
import Combine
import XCTest
import WalletConnectUtils
import Starscream
@testable import WalletConnectRelay

final class RelayClientEndToEndTests: XCTestCase {

    let defaultTimeout: TimeInterval = 10

    let relayHost = "relay.walletconnect.com"
    let projectId = "8ba9ee138960775e5231b70cc5ef1c3a"
    private var publishers = Set<AnyCancellable>()

    func makeRelayClient() -> RelayClient {
        let clientIdStorage = ClientIdStorage(keychain: KeychainStorageMock())
        let socketAuthenticator = SocketAuthenticator(
            clientIdStorage: clientIdStorage,
            didKeyFactory: ED25519DIDKeyFactory(),
            relayHost: relayHost
        )
        let urlFactory = RelayUrlFactory(socketAuthenticator: socketAuthenticator)
        let socket = WebSocket(url: urlFactory.create(host: relayHost, projectId: projectId))

        let logger = ConsoleLogger()
        let dispatcher = Dispatcher(socket: socket, socketConnectionHandler: ManualSocketConnectionHandler(socket: socket), logger: logger)
        return RelayClient(dispatcher: dispatcher, logger: logger, keyValueStorage: RuntimeKeyValueStorage())
    }

    func testSubscribe() {
        let relayClient = makeRelayClient()

        try! relayClient.connect()
        let subscribeExpectation = expectation(description: "subscribe call succeeds")
        subscribeExpectation.assertForOverFulfill = true
        relayClient.socketConnectionStatusPublisher.sink { status in
            if status == .connected {
                relayClient.subscribe(topic: "qwerty") { error in
                    XCTAssertNil(error)
                    subscribeExpectation.fulfill()
                }
            }
        }.store(in: &publishers)

        wait(for: [subscribeExpectation], timeout: defaultTimeout)
    }

    func testEndToEndPayload() {
        let relayA = makeRelayClient()
        let relayB = makeRelayClient()

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
            relayA.publish(topic: randomTopic, payload: payloadA, tag: 0, onNetworkAcknowledge: { error in
                XCTAssertNil(error)
            })
            relayA.subscribe(topic: randomTopic) { error in
                XCTAssertNil(error)
            }
        }.store(in: &publishers)
        relayB.socketConnectionStatusPublisher.sink {  _ in
            relayB.publish(topic: randomTopic, payload: payloadB, tag: 0, onNetworkAcknowledge: { error in
                XCTAssertNil(error)
            })
            relayB.subscribe(topic: randomTopic) { error in
                XCTAssertNil(error)
            }
        }.store(in: &publishers)

        wait(for: [expectationA, expectationB], timeout: defaultTimeout)

        XCTAssertEqual(subscriptionATopic, randomTopic)
        XCTAssertEqual(subscriptionBTopic, randomTopic)

        // TODO - uncomment lines when request rebound is resolved
//        XCTAssertEqual(subscriptionBPayload, payloadA)
//        XCTAssertEqual(subscriptionAPayload, payloadB)
    }
}

extension String {
    static func randomTopic() -> String {
        "\(UUID().uuidString)\(UUID().uuidString)".replacingOccurrences(of: "-", with: "").lowercased()
    }
}
