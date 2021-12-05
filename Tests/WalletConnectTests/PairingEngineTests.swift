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

import CryptoKit

extension WalletConnectURI {
    
    static func stub(isController: Bool = false) -> WalletConnectURI {
        WalletConnectURI(
            topic: String.generateTopic()!,
            publicKey: Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation.toHexString(),
            isController: isController,
            relay: RelayProtocolOptions(protocol: "", params: nil)
        )
    }
}

fileprivate extension WCRequest {
    
    var approveParams: PairingType.ApproveParams? {
        guard case .pairingApprove(let approveParams) = self.params else { return nil }
        return approveParams
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
    
    var relayMock: MockedWCRelay!
    var cryptoMock: CryptoStorageProtocolMock!
    var subscriberMock: MockedSubscriber!
    var storageMock: PairingSequenceStorageMock!
    
    var topicGenerator: TopicGenerator!
    
    override func setUp() {
        cryptoMock = CryptoStorageProtocolMock()
        relayMock = MockedWCRelay()
        subscriberMock = MockedSubscriber()
        storageMock = PairingSequenceStorageMock()
        topicGenerator = TopicGenerator()
    }

    override func tearDown() {
        relayMock = nil
        engine = nil
        cryptoMock = nil
    }
    
    func setupEngine(isController: Bool) {
        let meta = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
        let logger = ConsoleLogger()
        engine = PairingEngine(
            relay: relayMock,
            crypto: cryptoMock,
            subscriber: subscriberMock,
            sequencesStore: storageMock,
            isController: isController,
            metadata: meta,
            logger: logger,
            topicGenerator: topicGenerator.getTopic)
    }
    
    func testPropose() {
        setupEngine(isController: false)
        
        let topicA = topicGenerator.topic
        let uri = engine.propose(permissions: SessionType.Permissions.stub())!
        
        XCTAssert(cryptoMock.hasPrivateKey(for: uri.publicKey))
        XCTAssert(storageMock.hasSequence(forTopic: topicA)) // TODO: check for pending state
        XCTAssert(subscriberMock.didSubscribe(to: topicA), "Proposer must subscribe to topic A to listen for approval message.")
    }
    

    func deriveTopic(publicKey: String, privateKey: Crypto.X25519.PrivateKey) -> String {
        try! Crypto.X25519.generateAgreementKeys(peerPublicKey: Data(hex: publicKey), privateKey: privateKey).derivedTopic()
    }
    
    func testApprove() throws {
        setupEngine(isController: true)
        
        let uri = WalletConnectURI.stub()
        let topicA = uri.topic
        let topicB = deriveTopic(publicKey: uri.publicKey, privateKey: cryptoMock.privateKeyStub)

        try engine.approve(uri) { _ in }

        guard let publishTopic = relayMock.requests.first?.topic, let approval = relayMock.requests.first?.request.approveParams else {
            XCTFail("Responder must publish an approval request."); return
        }

        XCTAssert(subscriberMock.didSubscribe(to: topicA), "Responder must subscribe to topic A to listen for approval request acknowledgement.")
        XCTAssert(subscriberMock.didSubscribe(to: topicB))
        XCTAssert(cryptoMock.hasPrivateKey(for: approval.responder.publicKey))
        XCTAssert(cryptoMock.hasAgreementKeys(for: topicB))
        XCTAssert(storageMock.hasSequence(forTopic: topicB)) // check for pre-settled
        XCTAssertEqual(publishTopic, topicA)
    }
    
    func testApproveMultipleCallsThrottleOnSameURI() {
        setupEngine(isController: true)
        let uri = WalletConnectURI.stub()
        for i in 1...10 {
            if i == 1 {
                XCTAssertNoThrow(try engine.approve(uri) { _ in })
            } else {
                XCTAssertThrowsError(try engine.approve(uri) { _ in })
            }
        }
    }
    
    // TODO: approve acknowledgement tests for success and failure
    
    func testReceiveApprovalResponse() {
        setupEngine(isController: false)
        
        let responderPubKey = Crypto.X25519.PrivateKey().publicKey.rawRepresentation.toHexString()
        let topicB = deriveTopic(publicKey: responderPubKey, privateKey: cryptoMock.privateKeyStub)
        let uri = engine.propose(permissions: SessionType.Permissions.stub())!
        let topicA = uri.topic
        
        let approveParams = PairingType.ApproveParams(
            relay: RelayProtocolOptions(protocol: "", params: nil),
            responder: PairingType.Participant(publicKey: responderPubKey),
            expiry: Time.day,
            state: nil)
        let request = WCRequest(method: .pairingApprove, params: .pairingApprove(approveParams))
        let payload = WCRequestSubscriptionPayload(topic: topicA, wcRequest: request)
        
        subscriberMock.onReceivePayload?(payload)
        
        XCTAssert(subscriberMock.didUnsubscribe(to: topicA))
        XCTAssert(subscriberMock.didSubscribe(to: topicB))
        XCTAssert(cryptoMock.hasPrivateKey(for: uri.publicKey))
        XCTAssert(cryptoMock.hasAgreementKeys(for: topicB))
        XCTAssert(storageMock.hasSequence(forTopic: topicB)) // check state
        XCTAssertFalse(storageMock.hasSequence(forTopic: topicA))
        // TODO: assert JSON-RPC respond
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
