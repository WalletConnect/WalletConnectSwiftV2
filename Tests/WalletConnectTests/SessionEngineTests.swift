import XCTest
import WalletConnectUtils
import TestingUtils
@testable import WalletConnect

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
    }

    override func tearDown() {
        relayMock = nil
        subscriberMock = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        engine = nil
    }
    
    func setupEngine(isController: Bool) {
        metadata = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
        self.isController = isController
        let logger = ConsoleLoggerMock()
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
    
    func testPropose() {
        setupEngine(isController: false)
        
        let pairing = Pairing.stub()
        
        let topicB = pairing.topic
        let topicC = topicGenerator.topic
        
        let agreementKeys = AgreementSecret.stub()
        cryptoMock.setAgreementSecret(agreementKeys, topic: topicB)
        let permissions = SessionPermissions.stub()
        let relayOptions = RelayProtocolOptions(protocol: "", params: nil)
        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
        
        guard let publishTopic = relayMock.requests.first?.topic, let proposal = relayMock.requests.first?.request.sessionProposal else {
            XCTFail("Proposer must publish a proposal request."); return
        }
        
        XCTAssert(subscriberMock.didSubscribe(to: topicC), "Proposer must subscribe to topic C to listen for approval message.")
        XCTAssert(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must store the private key matching the public key sent through the proposal.")
        XCTAssert(cryptoMock.hasAgreementSecret(for: topicB))
        XCTAssert(storageMock.hasPendingProposedPairing(on: topicC), "The engine must store a pending session on proposed state.")
        
        XCTAssertEqual(publishTopic, topicB)
        XCTAssertEqual(proposal.topic, topicC)
    }
    
    func testProposeResponseFailure() {
        setupEngine(isController: false)
        let pairing = Pairing.stub()
        
        let topicB = pairing.topic
        let topicC = topicGenerator.topic
        
        let agreementKeys = AgreementSecret.stub()
        cryptoMock.setAgreementSecret(agreementKeys, topic: topicB)
        let permissions = SessionPermissions.stub()
        let relayOptions = RelayProtocolOptions(protocol: "", params: nil)
        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
        
        guard let publishTopic = relayMock.requests.first?.topic, let request = relayMock.requests.first?.request else {
            XCTFail("Proposer must publish a proposal request."); return
        }
        let error = JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))
        let response = WCResponse(
            topic: publishTopic,
            requestMethod: request.method,
            requestParams: request.params,
            result: .failure(error))
        relayMock.onResponse?(response)
        
        XCTAssert(subscriberMock.didUnsubscribe(to: topicC))
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: request.sessionProposal?.proposer.publicKey ?? ""))
        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: topicB))
        XCTAssertFalse(storageMock.hasSequence(forTopic: topicC))
    }
    
    func testApprove() {
        setupEngine(isController: true)
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let topicB = String.generateTopic()!
        let topicC = String.generateTopic()!
        let topicD = deriveTopic(publicKey: proposerPubKey, privateKey: cryptoMock.privateKeyStub)
        
        let proposer = SessionType.Proposer(publicKey: proposerPubKey, controller: isController, metadata: metadata)
        let proposal = SessionProposal(
            topic: topicC,
            relay: RelayProtocolOptions(protocol: "", params: nil),
            proposer: proposer,
            signal: SessionType.Signal(method: "pairing", params: SessionType.Signal.Params(topic: topicB)),
            permissions: SessionPermissions.stub(),
            ttl: SessionSequence.timeToLivePending)
            
        engine.approve(proposal: proposal, accounts: [])
        
        guard let publishTopic = relayMock.requests.first?.topic, let approval = relayMock.requests.first?.request.approveParams else {
            XCTFail("Responder must publish an approval request."); return
        }
        
        XCTAssert(subscriberMock.didSubscribe(to: topicC))
        XCTAssert(subscriberMock.didSubscribe(to: topicD))
        XCTAssert(cryptoMock.hasPrivateKey(for: approval.responder.publicKey))
        XCTAssert(cryptoMock.hasAgreementSecret(for: topicD))
        XCTAssert(storageMock.hasSequence(forTopic: topicC)) // TODO: check state
        XCTAssert(storageMock.hasSequence(forTopic: topicD)) // TODO: check state
        XCTAssertEqual(publishTopic, topicC)
    }
    
    func testApprovalAcknowledgementSuccess() {
        setupEngine(isController: true)
        
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let topicB = String.generateTopic()!
        let topicC = String.generateTopic()!
        let topicD = deriveTopic(publicKey: proposerPubKey, privateKey: cryptoMock.privateKeyStub)
        
        let agreementKeys = AgreementSecret.stub()
        cryptoMock.setAgreementSecret(agreementKeys, topic: topicC)
        
        let proposer = SessionType.Proposer(publicKey: proposerPubKey, controller: isController, metadata: metadata)
        let proposal = SessionProposal(
            topic: topicC,
            relay: RelayProtocolOptions(protocol: "", params: nil),
            proposer: proposer,
            signal: SessionType.Signal(method: "pairing", params: SessionType.Signal.Params(topic: topicB)),
            permissions: SessionPermissions.stub(),
            ttl: SessionSequence.timeToLivePending)
            
        engine.approve(proposal: proposal, accounts: [])
        
        guard let publishTopic = relayMock.requests.first?.topic, let request = relayMock.requests.first?.request else {
            XCTFail("Responder must publish an approval request."); return
        }
        let success = JSONRPCResponse<AnyCodable>(id: request.id, result: AnyCodable(true))
        let response = WCResponse(
            topic: publishTopic,
            requestMethod: request.method,
            requestParams: request.params,
            result: .success(success))
        relayMock.onResponse?(response)
    
        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: topicC))
        XCTAssertFalse(storageMock.hasSequence(forTopic: topicC)) // TODO: Check state
        XCTAssert(subscriberMock.didUnsubscribe(to: topicC))
    }
    
    func testApprovalAcknowledgementFailure() {
        setupEngine(isController: true)
        
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let selfPubKey = cryptoMock.privateKeyStub.publicKey.hexRepresentation
        let topicB = String.generateTopic()!
        let topicC = String.generateTopic()!
        let topicD = deriveTopic(publicKey: proposerPubKey, privateKey: cryptoMock.privateKeyStub)
        
        let agreementKeys = AgreementSecret.stub()
        cryptoMock.setAgreementSecret(agreementKeys, topic: topicC)
        
        let proposer = SessionType.Proposer(publicKey: proposerPubKey, controller: isController, metadata: metadata)
        let proposal = SessionProposal(
            topic: topicC,
            relay: RelayProtocolOptions(protocol: "", params: nil),
            proposer: proposer,
            signal: SessionType.Signal(method: "pairing", params: SessionType.Signal.Params(topic: topicB)),
            permissions: SessionPermissions.stub(),
            ttl: SessionSequence.timeToLivePending)
            
        engine.approve(proposal: proposal, accounts: [])
        
        guard let publishTopic = relayMock.requests.first?.topic, let request = relayMock.requests.first?.request else {
            XCTFail("Responder must publish an approval request."); return
        }
        let error = JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))
        let response = WCResponse(
            topic: publishTopic,
            requestMethod: request.method,
            requestParams: request.params,
            result: .failure(error))
        relayMock.onResponse?(response)
        
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: selfPubKey))
        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: topicC))
        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: topicD))
        XCTAssertFalse(storageMock.hasSequence(forTopic: topicC)) // TODO: Check state
        XCTAssertFalse(storageMock.hasSequence(forTopic: topicD))
        XCTAssert(subscriberMock.didUnsubscribe(to: topicC))
        XCTAssert(subscriberMock.didUnsubscribe(to: topicD))
        // TODO: assert session settlement callback
    }
    
    func testReceiveApprovalResponse() {
        setupEngine(isController: false)

        var approvedSession: Session?

        let privateKeyStub = cryptoMock.privateKeyStub
        let proposerPubKey = privateKeyStub.publicKey.hexRepresentation
        let responderPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let topicC = topicGenerator.topic
        let topicD = deriveTopic(publicKey: responderPubKey, privateKey: privateKeyStub)

        let permissions = SessionPermissions.stub()
        let relayOptions = RelayProtocolOptions(protocol: "", params: nil)
        let approveParams = SessionType.ApproveParams(
            relay: relayOptions,
            responder: SessionParticipant(publicKey: responderPubKey, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil)),
            expiry: Time.day,
            state: SessionState(accounts: []))
        let request = WCRequest(method: .sessionApprove, params: .sessionApprove(approveParams))
        let payload = WCRequestSubscriptionPayload(topic: topicC, wcRequest: request)
        let pairing = Pairing.stub()

        let agreementKeys = AgreementSecret.stub()
        cryptoMock.setAgreementSecret(agreementKeys, topic: pairing.topic)

        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
        engine.onSessionApproved = { session in
            approvedSession = session
        }
        subscriberMock.onReceivePayload?(payload)

        XCTAssert(subscriberMock.didUnsubscribe(to: topicC)) // FIXME: Actually, only on acknowledgement
        XCTAssert(subscriberMock.didSubscribe(to: topicD))
        XCTAssert(cryptoMock.hasPrivateKey(for: proposerPubKey))
        XCTAssert(cryptoMock.hasAgreementSecret(for: topicD))
        XCTAssert(storageMock.hasSequence(forTopic: topicD)) // TODO: check for state
        XCTAssertNotNil(approvedSession)
        XCTAssertEqual(approvedSession?.topic, topicD)
    }
    
    // MARK: - Update call tests
    
    func testUpdate() throws {
        setupEngine(isController: true)
        let session = SessionSequence.stubSettled()
        storageMock.setSequence(session)
        try engine.update(topic: session.topic, accounts: ["std:0:0"])
        XCTAssertTrue(relayMock.didCallRequest)
    }
    
    func testUpdateErrorInvalidAccount() {
        setupEngine(isController: true)
        let session = SessionSequence.stubSettled()
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.update(topic: session.topic, accounts: ["err"]))
    }
    
    func testUpdateErrorIfNonController() {
        setupEngine(isController: false)
        let session = SessionSequence.stubSettled()
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.update(topic: session.topic, accounts: ["std:0:0"]), "Update must fail if called by a non-controller.")
    }
    
    func testUpdateErrorSessionNotFound() {
        setupEngine(isController: true)
        XCTAssertThrowsError(try engine.update(topic: "", accounts: ["std:0:0"]), "Update must fail if there is no session matching the target topic.")
    }
    
    func testUpdateErrorSessionNotSettled() {
        setupEngine(isController: true)
        let session = SessionSequence.stubPreSettled()
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.update(topic: session.topic, accounts: ["std:0:0"]), "Update must fail if session is not on settled state.")
    }
    
    // MARK: - Update peer response tests
    
    func testUpdatePeer() {
        setupEngine(isController: false)
        let session = SessionSequence.stubSettled(isPeerController: true)
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic))
        XCTAssertTrue(relayMock.didRespondSuccess)
    }
    
    func testUpdatePeerErrorAccountInvalid() {
        setupEngine(isController: false)
        let session = SessionSequence.stubSettled(isPeerController: true)
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic, accounts: ["0"]))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1003)
    }
    
    func testUpdatePeerErrorNoSession() {
        setupEngine(isController: false)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: ""))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1301)
    }
    
    func testUpdatePeerErrorSessionNotSettled() {
        setupEngine(isController: false)
        let session = SessionSequence.stubPreSettled(isPeerController: true) // Session is not fully settled
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3003)
    }
    
    func testUpdatePeerErrorUnauthorized() {
        setupEngine(isController: false)
        let session = SessionSequence.stubSettled() // Peer is not a controller
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3003)
    }
    
    func testUpdatePeerErrorMatchingController() {
        setupEngine(isController: true) // Update request received by a controller
        let session = SessionSequence.stubSettled(isPeerController: true)
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3005)
    }
    
    // TODO: Update acknowledgement tests
    
    // MARK: - Upgrade call tests
    
    func testUpgradeSuccess() throws {
        setupEngine(isController: true)
        let session = SessionSequence.stubSettled()
        storageMock.setSequence(session)
        try engine.upgrade(topic: session.topic, permissions: Session.Permissions.stub())
        XCTAssertTrue(relayMock.didCallRequest)
    }
    
    func testUpgradeErrorSessionNotFound() {
        
    }
    
    func testUpgradeErrorSessionNotSettled() {
        
    }
    
    func testUpgradeErrorInvalidPermissions() {
        
    }
    
    func testUpgradeErrorCalledByNonController() {
        
    }
}
