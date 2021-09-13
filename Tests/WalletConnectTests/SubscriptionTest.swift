
import Foundation
import XCTest
@testable import WalletConnect

class SubscriptionTest: XCTestCase {
    var relay: MockedRelay!
    var subscription: Subscription!
    override func setUp() {
        relay = MockedRelay()
        subscription = Subscription(relay: relay)
    }

    override func tearDown() {
        relay = nil
        subscription = nil
    }
    
    func testSetGetSubscription() {
        let topic = "1234"
        let sequenceData = SequenceData.pending(testPendingSequence)
        subscription.set(topic: topic, sequenceData: sequenceData)
        XCTAssertNotNil(subscription.get(topic: topic))
        XCTAssertTrue(relay.didCallSubscribe)
    }
    
    func testRemoveSubscription() {
        let topic = "1234"
        let sequenceData = SequenceData.pending(testPendingSequence)
        subscription.set(topic: topic, sequenceData: sequenceData)
        subscription.remove(topic: topic)
        XCTAssertNil(subscription.get(topic: topic))
        XCTAssertTrue(relay.didCallUnsubscribe)
    }
}

fileprivate let testPendingSequence = PairingType.Pending(status: .proposed,
                                                          topic: "1234",
                                                          relay: RelayProtocolOptions(protocol: "",
                                                                                      params: nil),
                                                          self: PairingType.Participant(publicKey: ""),
                                                          proposal: PairingType.Proposal(topic: "",
                                                                                         relay: RelayProtocolOptions(protocol: "",
                                                                                                                     params: nil),
                                                                                         proposer: PairingType.Proposer(publicKey: "",
                                                                                                                        controller: false),
                                                                                         signal: PairingType.Signal(params: PairingType.Signal.Params(uri: "")),
                                                                                         permissions: PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [])), ttl: 0))
