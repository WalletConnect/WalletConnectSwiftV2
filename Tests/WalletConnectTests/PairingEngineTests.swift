import XCTest
@testable import WalletConnect

fileprivate extension SessionType.Permissions {
    static func stub() -> SessionType.Permissions {
        SessionType.Permissions(
            blockchain: SessionType.Blockchain(chains: []),
            jsonrpc: SessionType.JSONRPC(methods: []),
            notifications: SessionType.Notifications(types: [])
        )
    }
}

final class TopicGenerator {
    
    let topic: String
    
    init(topic: String = String.generateTopic()!) {
        self.topic = topic
    }
    
    func getTopic() -> String? {
        return topic
    }
}

class PairingEngineTests: XCTestCase {
    
    var engine: PairingEngine!
    
    var relay: MockedWCRelay!
    var cryptoMock: CryptoStorageProtocolMock!
    var subscriberMock: MockedSubscriber!
    var storageMock: PairingSequenceStorageMock!
    
    var topicGenerator: TopicGenerator!
    
    override func setUp() {
        cryptoMock = CryptoStorageProtocolMock()
        relay = MockedWCRelay()
        subscriberMock = MockedSubscriber()
        let meta = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
        let logger = ConsoleLogger()
        storageMock = PairingSequenceStorageMock()
        topicGenerator = TopicGenerator()
        engine = PairingEngine(
            relay: relay,
            crypto: cryptoMock,
            subscriber: subscriberMock,
            sequencesStore: storageMock,
            isController: false,
            metadata: meta,
            logger: logger,
            topicGenerator: topicGenerator.getTopic)
    }

    override func tearDown() {
        relay = nil
        engine = nil
        cryptoMock = nil
    }
    
    func testPropose() {
        let topicA = topicGenerator.topic
        let uri = engine.propose(permissions: SessionType.Permissions.stub())!
        
        XCTAssert(cryptoMock.hasPrivateKey(for: uri.publicKey))
        XCTAssert(storageMock.hasSequence(forTopic: topicA)) // TODO: check for pending state
        XCTAssert(subscriberMock.didSubscribe(to: topicA))
    }
    
//    func testNotifyOnSessionProposal() {
//        let topic = "1234"
//        let proposalExpectation = expectation(description: "on session proposal is called after pairing payload")
////        engine.sequencesStore.create(topic: topic, sequenceState: sequencePendingState)
//        try? engine.sequencesStore.setSequence(pendingPairing)
//        let subscriptionPayload = WCRequestSubscriptionPayload(topic: topic, clientSynchJsonRpc: sessionProposal)
//        engine.onSessionProposal = { (_) in
//            proposalExpectation.fulfill()
//        }
//        subscriber.onRequestSubscription?(subscriptionPayload)
//        waitForExpectations(timeout: 0.01, handler: nil)
//    }
}

fileprivate let sessionProposal = WCRequest(id: 0,
                                                     jsonrpc: "2.0",
                                                     method: WCRequest.Method.pairingPayload,
                                                     params: WCRequest.Params.pairingPayload(PairingType.PayloadParams(request: PairingType.PayloadParams.Request(method: .sessionPropose, params: SessionType.ProposeParams(topic: "", relay: RelayProtocolOptions(protocol: "", params: []), proposer: SessionType.Proposer(publicKey: "", controller: false, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil)), signal: SessionType.Signal(method: "", params: SessionType.Signal.Params(topic: "")), permissions: SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []), notifications: SessionType.Notifications(types: [])), ttl: 100)))))

//fileprivate let sequencePendingState = PairingType.SequenceState.pending(PairingType.Pending(status: PairingType.Pending.PendingStatus(rawValue: "proposed")!, topic: "1234", relay: RelayProtocolOptions(protocol: "", params: nil), self: PairingType.Participant(publicKey: ""), proposal: PairingType.Proposal(topic: "", relay: RelayProtocolOptions(protocol: "", params: nil), proposer: PairingType.Proposer(publicKey: "", controller: false), signal: PairingType.Signal(params: PairingType.Signal.Params(uri: "")), permissions: PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [])), ttl: 100)))
//
//fileprivate let pendingPairing = PairingSequence(topic: "1234", relay: RelayProtocolOptions(protocol: "", params: nil), selfParticipant: PairingType.Participant(publicKey: ""), expiryDate: Date(timeIntervalSinceNow: 10), pendingState: PairingSequence.Pending(proposal: PairingType.Proposal(topic: "", relay: RelayProtocolOptions(protocol: "", params: nil), proposer: PairingType.Proposer(publicKey: "", controller: false), signal: PairingType.Signal(params: PairingType.Signal.Params(uri: "")), permissions: PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [])), ttl: 100), status: .proposed))
