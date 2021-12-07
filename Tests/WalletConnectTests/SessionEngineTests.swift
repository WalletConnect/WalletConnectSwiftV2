import XCTest
@testable import WalletConnect

// TODO: Move common helper methods to a shared folder
fileprivate extension Pairing {
    
    static func stub() -> Pairing {
        Pairing(topic: String.generateTopic()!, peer: nil)
    }
}

fileprivate extension SessionType.Permissions {
    
    static func stub() -> SessionType.Permissions {
        SessionType.Permissions(
            blockchain: SessionType.Blockchain(chains: []),
            jsonrpc: SessionType.JSONRPC(methods: []),
            notifications: SessionType.Notifications(types: [])
        )
    }
}

fileprivate extension WCRequest {
    
    var sessionProposal: SessionType.Proposal? {
        guard case .pairingPayload(let payload) = self.params else { return nil }
        return payload.request.params
    }
    
    var approveParams: SessionType.ApproveParams? {
        guard case .sessionApprove(let approveParams) = self.params else { return nil }
        return approveParams
    }
}

fileprivate func deriveTopic(publicKey: String, privateKey: Crypto.X25519.PrivateKey) -> String {
    try! Crypto.X25519.generateAgreementKeys(peerPublicKey: Data(hex: publicKey), privateKey: privateKey).derivedTopic()
}

final class SessionEngineTests: XCTestCase {
    
    var engine: SessionEngine!

    var relayMock: MockedWCRelay!
    var subscriberMock: MockedSubscriber!
    var storageMock: SessionSequenceStorageMock!
    var cryptoMock: CryptoStorageProtocolMock!
    
    var topicGenerator: TopicGenerator!
    
    var isController: Bool!
    var metadata: AppMetadata!
    
    override func setUp() {
        relayMock = MockedWCRelay()
        subscriberMock = MockedSubscriber()
        storageMock = SessionSequenceStorageMock()
        cryptoMock = CryptoStorageProtocolMock()
        topicGenerator = TopicGenerator()
        
        metadata = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
        isController = false
        let logger = ConsoleLogger()
        engine = SessionEngine(
            relay: relayMock,
            crypto: cryptoMock,
            subscriber: subscriberMock,
            sequencesStore: storageMock,
            isController: isController,
            metadata: metadata,
            logger: logger,
            topicGenerator: topicGenerator.getTopic)
    }

    override func tearDown() {
        relayMock = nil
        subscriberMock = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        engine = nil
    }
    
    func testPropose() {
        let pairing = Pairing.stub()
        
        let topicB = pairing.topic
        let topicC = topicGenerator.topic
        
        let permissions = SessionType.Permissions.stub()
        let relayOptions = RelayProtocolOptions(protocol: "", params: nil)
        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
        
        guard let publishTopic = relayMock.requests.first?.topic, let proposal = relayMock.requests.first?.request.sessionProposal else {
            XCTFail("Proposer must publish an approval request."); return
        }
        
        XCTAssert(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey))
        XCTAssert(storageMock.hasSequence(forTopic: topicC)) // TODO: check state
        XCTAssert(subscriberMock.didSubscribe(to: topicC))
        XCTAssertEqual(publishTopic, topicB)
        XCTAssertEqual(proposal.topic, topicC)
        // TODO: check for agreement keys transpose
    }
    
    func testApprove() {
        let proposerPubKey = Crypto.X25519.PrivateKey().publicKey.toHexString()
        let topicB = String.generateTopic()!
        let topicC = String.generateTopic()!
        let topicD = deriveTopic(publicKey: proposerPubKey, privateKey: cryptoMock.privateKeyStub)
        
        let proposer = SessionType.Proposer(publicKey: proposerPubKey, controller: isController, metadata: metadata)
        let proposal = SessionType.Proposal(
            topic: topicC,
            relay: RelayProtocolOptions(protocol: "", params: nil),
            proposer: proposer,
            signal: SessionType.Signal(method: "pairing", params: SessionType.Signal.Params(topic: topicB)),
            permissions: SessionType.Permissions.stub(),
            ttl: SessionSequence.timeToLivePending)
            
        engine.approve(proposal: proposal, accounts: []) { _ in }
        
        guard let publishTopic = relayMock.requests.first?.topic, let approval = relayMock.requests.first?.request.approveParams else {
            XCTFail("Responder must publish an approval request."); return
        }
        
        XCTAssert(subscriberMock.didSubscribe(to: topicC))
        XCTAssert(subscriberMock.didSubscribe(to: topicD))
        XCTAssert(cryptoMock.hasPrivateKey(for: approval.responder.publicKey))
        XCTAssert(cryptoMock.hasAgreementKeys(for: topicD))
        XCTAssert(storageMock.hasSequence(forTopic: topicD)) // TODO: check state
        XCTAssertEqual(publishTopic, topicC)
    }
    
    // TODO: approve acknowledgement tests for success and failure
    
    func testReceiveApprovalResponse() {
        
        var approvedSession: Session?
        
        let privateKeyStub = cryptoMock.privateKeyStub
        let proposerPubKey = privateKeyStub.publicKey.toHexString()
        let responderPubKey = Crypto.X25519.PrivateKey().publicKey.rawRepresentation.toHexString()
        let topicC = topicGenerator.topic
        let topicD = deriveTopic(publicKey: responderPubKey, privateKey: privateKeyStub)
        
        let permissions = SessionType.Permissions.stub()
        let relayOptions = RelayProtocolOptions(protocol: "", params: nil)
        let approveParams = SessionType.ApproveParams(
            relay: relayOptions,
            responder: SessionType.Participant(publicKey: responderPubKey, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil)),
            expiry: Time.day,
            state: SessionType.State(accounts: []))
        let request = WCRequest(method: .sessionApprove, params: .sessionApprove(approveParams))
        let payload = WCRequestSubscriptionPayload(topic: topicC, wcRequest: request)
        let pairing = Pairing.stub()
        
        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
        engine.onSessionApproved = { session in
            approvedSession = session
        }
        subscriberMock.onReceivePayload?(payload)
        
        XCTAssert(subscriberMock.didUnsubscribe(to: topicC)) // FIXME: Actually, only on acknowledgement
        XCTAssert(subscriberMock.didSubscribe(to: topicD))
        XCTAssert(cryptoMock.hasPrivateKey(for: proposerPubKey))
        XCTAssert(cryptoMock.hasAgreementKeys(for: topicD))
        XCTAssert(storageMock.hasSequence(forTopic: topicD)) // TODO: check for state
        XCTAssertNotNil(approvedSession)
        XCTAssertEqual(approvedSession?.topic, topicD)
    }
}
