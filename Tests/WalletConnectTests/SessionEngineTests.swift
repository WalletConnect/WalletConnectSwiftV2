import XCTest
import WalletConnectUtils
@testable import TestingUtils
import WalletConnectKMS
@testable import WalletConnect

extension Collection where Self.Element == String {
    func toAccountSet() -> Set<Account> {
        Set(self.map { Account($0)! })
    }
}

final class SessionEngineTests: XCTestCase {
    
    var engine: SessionEngine!

    var relayMock: MockedWCRelay!
    var subscriberMock: MockedSubscriber!
    var storageMock: SessionSequenceStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    
    var topicGenerator: TopicGenerator!
    
    var metadata: AppMetadata!
    
    override func setUp() {
        relayMock = MockedWCRelay()
        subscriberMock = MockedSubscriber()
        storageMock = SessionSequenceStorageMock()
        cryptoMock = KeyManagementServiceMock()
        topicGenerator = TopicGenerator()
        setupEngine()
    }

    override func tearDown() {
        relayMock = nil
        subscriberMock = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        engine = nil
    }
    
    func setupEngine() {
        metadata = AppMetadata.stub()
        let logger = ConsoleLoggerMock()
        engine = SessionEngine(
            relay: relayMock,
            kms: cryptoMock,
            subscriber: subscriberMock,
            sequencesStore: storageMock,
            metadata: metadata,
            logger: logger,
            topicGenerator: topicGenerator.getTopic)
    }
    

    
    func testSessionSettle() {
        let agreementKeys = AgreementSecret.stub()
        let topicB = String.generateTopic()
        cryptoMock.setAgreementSecret(agreementKeys, topic: topicB)
        
        let proposal = SessionProposal.stub(proposerPubKey: AgreementPrivateKey().publicKey.hexRepresentation)
        
        engine.settle(topic: topicB, proposal: proposal, accounts: [])
        
        XCTAssertTrue(storageMock.hasSequence(forTopic: topicB), "Responder must persist session on topic B")
        XCTAssert(subscriberMock.didSubscribe(to: topicB), "Responder must subscribe for topic B")
        XCTAssertTrue(relayMock.didCallRequest, "Responder must send session settle payload on topic B")
    }
    
    func testHandleSessionSettle() {
        let sessionTopic = String.generateTopic()
        cryptoMock.setAgreementSecret(AgreementSecret.stub(), topic: sessionTopic)
        var didCallBackOnSessionApproved = false
        engine.onSessionApproved = { _ in
            didCallBackOnSessionApproved = true
        }
        
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubSettle(topic: sessionTopic))
        
        XCTAssertTrue(storageMock.getSequence(forTopic: sessionTopic)!.acknowledged, "Proposer must store acknowledged session on topic B")
        XCTAssertTrue(relayMock.didRespondSuccess, "Proposer must send acknowledge on settle request")
        XCTAssertTrue(didCallBackOnSessionApproved, "Proposer's engine must call back with session")
    }
    
    func testHandleSessionSettleAcknowledge() {
        let session = SessionSequence.stub(isSelfController: true, acknowledged: false)
        storageMock.setSequence(session)
        var didCallBackOnSessionApproved = false
        engine.onSessionApproved = { _ in
            didCallBackOnSessionApproved = true
        }
        
        let settleResponse = JSONRPCResponse(id: 1, result: AnyCodable(true))
        let response = WCResponse(
            topic: session.topic,
            chainId: nil,
            requestMethod: .sessionSettle,
            requestParams: .sessionSettle(SessionType.SettleParams.stub()),
            result: .response(settleResponse))
        relayMock.onResponse?(response)

        XCTAssertTrue(storageMock.getSequence(forTopic: session.topic)!.acknowledged, "Responder must acknowledged session")
        XCTAssertTrue(didCallBackOnSessionApproved, "Responder's engine must call back with session")
    }
    
    func testHandleSessionSettleError() {
        let privateKey = AgreementPrivateKey()
        let session = SessionSequence.stub(isSelfController: false, selfPrivateKey: privateKey, acknowledged: false)
        storageMock.setSequence(session)
        cryptoMock.setAgreementSecret(AgreementSecret.stub(), topic: session.topic)
        try! cryptoMock.setPrivateKey(privateKey)
        
        let response = WCResponse(
            topic: session.topic,
            chainId: nil,
            requestMethod: .sessionSettle,
            requestParams: .sessionSettle(SessionType.SettleParams.stub()),
            result: .error(JSONRPCErrorResponse(id: 1, error: JSONRPCErrorResponse.Error(code: 0, message: ""))))
        relayMock.onResponse?(response)
        
        XCTAssertNil(storageMock.getSequence(forTopic: session.topic), "Responder must remove session")
        XCTAssertTrue(subscriberMock.didUnsubscribe(to: session.topic), "Responder must unsubscribe topic B")
        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: session.topic), "Responder must remove agreement secret")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: session.self.publicKey!), "Responder must remove private key")
    }

//    func testProposeResponseFailure() {
//        setupEngine()
//        let pairing = Pairing.stub()
//
//        let topicB = pairing.topic
//        let topicC = topicGenerator.topic
//
//        let agreementKeys = AgreementSecret.stub()
//        cryptoMock.setAgreementSecret(agreementKeys, topic: topicB)
//        let permissions = SessionPermissions.stub()
//        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
//        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
//
//        guard let publishTopic = relayMock.requests.first?.topic, let request = relayMock.requests.first?.request else {
//            XCTFail("Proposer must publish a proposal request."); return
//        }
//        let error = JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))
//        let response = WCResponse(
//            topic: publishTopic,
//            chainId: nil,
//            requestMethod: request.method,
//            requestParams: request.params,
//            result: .error(error))
//        relayMock.onResponse?(response)
//
//        XCTAssert(subscriberMock.didUnsubscribe(to: topicC))
//        XCTAssertFalse(cryptoMock.hasPrivateKey(for: request.sessionProposal?.proposer.publicKey ?? ""))
//        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: topicB))
//        XCTAssertFalse(storageMock.hasSequence(forTopic: topicC))
//    }
    
//    func testApprove() {
//        setupEngine()
//        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
//        let topicB = String.generateTopic()!
//        let topicC = String.generateTopic()!
//        let topicD = deriveTopic(publicKey: proposerPubKey, privateKey: cryptoMock.privateKeyStub)
//
//        let proposer = Proposer(publicKey: proposerPubKey, controller: true, metadata: metadata)
//        let proposal = SessionProposal(
//            topic: topicC,
//            relay: RelayProtocolOptions(protocol: "", data: nil),
//            proposer: proposer,
//            permissions: SessionPermissions.stub(),
//            blockchainProposed: BlockchainProposed.stub())
//
//        engine.approve(proposal: proposal, accounts: [])
//
//        guard let publishTopic = relayMock.requests.first?.topic, let approval = relayMock.requests.first?.request.approveParams else {
//            XCTFail("Responder must publish an approval request."); return
//        }
//
//        XCTAssert(subscriberMock.didSubscribe(to: topicC))
//        XCTAssert(subscriberMock.didSubscribe(to: topicD))
//        XCTAssert(cryptoMock.hasPrivateKey(for: approval.responder.publicKey))
//        XCTAssert(cryptoMock.hasAgreementSecret(for: topicD))
//        XCTAssert(storageMock.hasSequence(forTopic: topicC)) // TODO: check state
//        XCTAssert(storageMock.hasSequence(forTopic: topicD)) // TODO: check state
//        XCTAssertEqual(publishTopic, topicC)
//    }
    
//    func testApprovalAcknowledgementSuccess() {
//        setupEngine()
//
//        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
//        let topicB = String.generateTopic()!
//        let topicC = String.generateTopic()!
//        let topicD = deriveTopic(publicKey: proposerPubKey, privateKey: cryptoMock.privateKeyStub)
//
//        let agreementKeys = AgreementSecret.stub()
//        cryptoMock.setAgreementSecret(agreementKeys, topic: topicC)
//
//        let proposer = Proposer(publicKey: proposerPubKey, controller: true, metadata: metadata)
//        let proposal = SessionProposal(
//            topic: topicC,
//            relay: RelayProtocolOptions(protocol: "", data: nil),
//            proposer: proposer,
//            permissions: SessionPermissions.stub(),
//            blockchainProposed: BlockchainProposed.stub())
//
//        engine.approve(proposal: proposal, accounts: [])
//
//        guard let publishTopic = relayMock.requests.first?.topic, let request = relayMock.requests.first?.request else {
//            XCTFail("Responder must publish an approval request."); return
//        }
//        let success = JSONRPCResponse<AnyCodable>(id: request.id, result: AnyCodable(true))
//        let response = WCResponse(
//            topic: publishTopic,
//            chainId: nil,
//            requestMethod: request.method,
//            requestParams: request.params,
//            result: .response(success))
//        relayMock.onResponse?(response)
//
//        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: topicC))
//        XCTAssertFalse(storageMock.hasSequence(forTopic: topicC)) // TODO: Check state
//        XCTAssert(subscriberMock.didUnsubscribe(to: topicC))
//    }
    
//    func testApprovalAcknowledgementFailure() {
//        setupEngine()
//
//        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
//        let selfPubKey = cryptoMock.privateKeyStub.publicKey.hexRepresentation
//        let topicB = String.generateTopic()!
//        let topicC = String.generateTopic()!
//        let topicD = deriveTopic(publicKey: proposerPubKey, privateKey: cryptoMock.privateKeyStub)
//
//        let agreementKeys = AgreementSecret.stub()
//        cryptoMock.setAgreementSecret(agreementKeys, topic: topicC)
//
//        let proposer = Proposer(publicKey: proposerPubKey, controller: true, metadata: metadata)
//        let proposal = SessionProposal(
//            topic: topicC,
//            relay: RelayProtocolOptions(protocol: "", data: nil),
//            proposer: proposer,
//            permissions: SessionPermissions.stub(),
//            blockchainProposed: BlockchainProposed.stub())
//
//        engine.approve(proposal: proposal, accounts: [])
//
//        guard let publishTopic = relayMock.requests.first?.topic, let request = relayMock.requests.first?.request else {
//            XCTFail("Responder must publish an approval request."); return
//        }
//        let error = JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))
//        let response = WCResponse(
//            topic: publishTopic,
//            chainId: nil,
//            requestMethod: request.method,
//            requestParams: request.params,
//            result: .error(error))
//        relayMock.onResponse?(response)
//
//        XCTAssertFalse(cryptoMock.hasPrivateKey(for: selfPubKey))
//        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: topicC))
//        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: topicD))
//        XCTAssertFalse(storageMock.hasSequence(forTopic: topicC)) // TODO: Check state
//        XCTAssertFalse(storageMock.hasSequence(forTopic: topicD))
//        XCTAssert(subscriberMock.didUnsubscribe(to: topicC))
//        XCTAssert(subscriberMock.didUnsubscribe(to: topicD))
//        // TODO: assert session settlement callback
//    }
    

//    func testReceiveApprovalResponse() {
//        setupEngine()
//
//        var approvedSession: Session?
//
//        let privateKeyStub = cryptoMock.privateKeyStub
//        let proposerPubKey = privateKeyStub.publicKey.hexRepresentation
//        let responderPubKey = AgreementPrivateKey().publicKey.hexRepresentation
//        let topicC = topicGenerator.topic
//        let topicD = deriveTopic(publicKey: responderPubKey, privateKey: privateKeyStub)
//
//        let permissions = SessionPermissions.stub()
//        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
//        let approveParams = SessionType.ApproveParams(
//            relay: relayOptions,
//            responder: SessionParticipant(publicKey: responderPubKey, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil)),
//            expiry: Time.day,
//            state: SessionState(accounts: []))
//        let request = WCRequest(method: .sessionApprove, params: .sessionApprove(approveParams))
//        let payload = WCRequestSubscriptionPayload(topic: topicC, wcRequest: request)
//        let pairing = Pairing.stub()
//
//        let agreementKeys = AgreementSecret.stub()
//        cryptoMock.setAgreementSecret(agreementKeys, topic: pairing.topic)
//
//        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
//        engine.onSessionApproved = { session in
//            approvedSession = session
//        }
//        subscriberMock.onReceivePayload?(payload)
//
//        XCTAssert(subscriberMock.didUnsubscribe(to: topicC)) // FIXME: Actually, only on acknowledgement
//        XCTAssert(subscriberMock.didSubscribe(to: topicD))
//        XCTAssert(cryptoMock.hasPrivateKey(for: proposerPubKey))
//        XCTAssert(cryptoMock.hasAgreementSecret(for: topicD))
//        XCTAssert(storageMock.hasSequence(forTopic: topicD)) // TODO: check for state
//        XCTAssertNotNil(approvedSession)
//        XCTAssertEqual(approvedSession?.topic, topicD)
//    }

    
    // MARK: - Update call tests
    
    func testUpdateSuccess() throws {
        let updateAccounts = ["std:0:0"]
        let session = SessionSequence.stub(isSelfController: true)
        storageMock.setSequence(session)
        try engine.update(topic: session.topic, accounts: updateAccounts.toAccountSet())
        XCTAssertTrue(relayMock.didCallRequest)
    }
    
    func testUpdateErrorIfNonController() {
        let updateAccounts = ["std:0:0"]
        let session = SessionSequence.stub(isSelfController: false)
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.update(topic: session.topic, accounts: updateAccounts.toAccountSet()), "Update must fail if called by a non-controller.")
    }
    
    func testUpdateErrorSessionNotFound() {
        let updateAccounts = ["std:0:0"]
        XCTAssertThrowsError(try engine.update(topic: "", accounts: updateAccounts.toAccountSet()), "Update must fail if there is no session matching the target topic.")
    }
    
    func testUpdateErrorSessionNotSettled() {
        let updateAccounts = ["std:0:0"]
        let session = SessionSequence.stub(acknowledged: false)
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.update(topic: session.topic, accounts: updateAccounts.toAccountSet()), "Update must fail if session is not on settled state.")
    }
    
    // MARK: - Update peer response tests
    
    func testUpdatePeerSuccess() {
        let session = SessionSequence.stub(isSelfController: false)
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic))
        XCTAssertTrue(relayMock.didRespondSuccess)
    }
    
    func testUpdatePeerErrorAccountInvalid() {
        let session = SessionSequence.stub(isSelfController: false)
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic, accounts: ["0"]))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1003)
    }
    
    func testUpdatePeerErrorNoSession() {
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: ""))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1301)
    }

    func testUpdatePeerErrorUnauthorized() {
        let session = SessionSequence.stub(isSelfController: true) // Peer is not a controller
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3003)
    }
    // TODO: Update acknowledgement tests
    
    // MARK: - Upgrade call tests
    
    func testUpgradeSuccess() throws {
        let permissions = Session.Permissions.stub()
        let session = SessionSequence.stub(isSelfController: true)
        storageMock.setSequence(session)
        try engine.upgrade(topic: session.topic, permissions: permissions)
        XCTAssertTrue(relayMock.didCallRequest)
        // TODO: Check permissions on stored session
    }
    
    func testUpgradeErrorSessionNotFound() {
        XCTAssertThrowsError(try engine.upgrade(topic: "", permissions: Session.Permissions.stub())) { error in
            XCTAssertTrue(error.isNoSessionMatchingTopicError)
        }
    }
    
    func testUpgradeErrorSessionNotSettled() {
        let session = SessionSequence.stub(acknowledged: false)
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.upgrade(topic: session.topic, permissions: Session.Permissions.stub())) { error in
            XCTAssertTrue(error.isSessionNotSettledError)
        }
    }
    
    func testUpgradeErrorInvalidPermissions() {
        let session = SessionSequence.stub(isSelfController: true)
        storageMock.setSequence(session)
//        XCTAssertThrowsError(try engine.upgrade(topic: session.topic, permissions: Session.Permissions.stub())) { error in
//            XCTAssertTrue(error.isInvalidPermissionsError)
//        }
        XCTAssertThrowsError(try engine.upgrade(topic: session.topic, permissions: Session.Permissions.stub(methods: [""]))) { error in
            XCTAssertTrue(error.isInvalidPermissionsError)
        }
        XCTAssertThrowsError(try engine.upgrade(topic: session.topic, permissions: Session.Permissions.stub(notifications: [""]))) { error in
            XCTAssertTrue(error.isInvalidPermissionsError)
        }
    }
    
    func testUpgradeErrorCalledByNonController() {
        let session = SessionSequence.stub(isSelfController: false)
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.upgrade(topic: session.topic, permissions: Session.Permissions.stub())) { error in
            XCTAssertTrue(error.isUnauthorizedNonControllerCallError)
        }
    }
    
    // MARK: - Upgrade peer response tests
    
    func testUpgradePeerSuccess() {
        var didCallbackUpgrade = false
        let session = SessionSequence.stub(isSelfController: false)
        storageMock.setSequence(session)
        engine.onSessionUpgrade = { topic, _ in
            didCallbackUpgrade = true
            XCTAssertEqual(topic, session.topic)
        }
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpgrade(topic: session.topic))
        XCTAssertTrue(didCallbackUpgrade)
        XCTAssertTrue(relayMock.didRespondSuccess)
    }
    
//    func testUpgradePeerErrorInvalidPermissions() {
//        setupEngine()
//        let invalidPermissions = SessionPermissions.stub()
//        let session = SessionSequence.stubSettled(isSelfController: false)
//        storageMock.setSequence(session)
//        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpgrade(topic: session.topic, permissions: invalidPermissions))
//        XCTAssertFalse(relayMock.didRespondSuccess)
//        XCTAssertEqual(relayMock.lastErrorCode, 1004)
//    }
    
    func testUpgradePeerErrorSessionNotFound() {
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpgrade(topic: ""))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1301)
    }
    
    func testUpgradePeerErrorUnauthorized() {
        let session = SessionSequence.stub(isSelfController: true) // Peer is not a controller
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpgrade(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3004)
    }
    
    // MARK: - Session Extend on extending client
    
    func testExtendSuccess() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stub(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 2*Time.day
        XCTAssertNoThrow(try engine.extend(topic: session.topic, ttl: twoDays))
        let extendedSession = engine.getSettledSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(extendedSession.expiryDate.timeIntervalSinceReferenceDate, TimeTraveler.dateByAdding(days: 2).timeIntervalSinceReferenceDate, accuracy: 1)
    }
    
    func testExtendSessionNotSettled() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stub(isSelfController: false, expiryDate: tomorrow, acknowledged: false)
        storageMock.setSequence(session)
        let twoDays = 2*Time.day
        XCTAssertThrowsError(try engine.extend(topic: session.topic, ttl: twoDays))
    }
    
    func testExtendOnNonControllerClient() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 2*Time.day
        XCTAssertThrowsError(try engine.extend(topic: session.topic, ttl: twoDays))
    }
    
    func testExtendTtlTooHigh() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stub(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let tenDays = 10*Time.day
        XCTAssertThrowsError(try engine.extend(topic: session.topic, ttl: tenDays))
    }
    
    func testExtendTtlTooLow() {
        let dayAfterTommorow = TimeTraveler.dateByAdding(days: 2)
        let session = SessionSequence.stub(isSelfController: true, expiryDate: dayAfterTommorow)
        storageMock.setSequence(session)
        let oneDay = 1*Time.day
        XCTAssertThrowsError(try engine.extend(topic: session.topic, ttl: oneDay))
    }
    
    //MARK: - Handle Session Extend call from peer
    
    func testPeerExtendSuccess() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 2*Time.day
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubExtend(topic: session.topic, ttl: twoDays))
        let extendedSession = engine.getSettledSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(extendedSession.expiryDate.timeIntervalSinceReferenceDate, TimeTraveler.dateByAdding(days: 2).timeIntervalSinceReferenceDate, accuracy: 1)
    }
    
    func testPeerExtendUnauthorized() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stub(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 2*Time.day
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubExtend(topic: session.topic, ttl: twoDays))
        let potentiallyExtendedSession = engine.getSettledSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentiallyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 0.01, "expiry date has been extended for peer non controller request ")
    }
    
    func testPeerExtendTtlTooHigh() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 10*Time.day
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubExtend(topic: session.topic, ttl: twoDays))
        let potentaillyExtendedSession = engine.getSettledSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentaillyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 0.01, "expiry date has been extended despite ttl to high")
    }
    
    func testPeerExtendTtlTooLow() {
        let tomorrow = TimeTraveler.dateByAdding(days: 2)
        let session = SessionSequence.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 1*Time.day
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubExtend(topic: session.topic, ttl: twoDays))
        let potentaillyExtendedSession = engine.getSettledSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentaillyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 0.01, "expiry date has been extended despite ttl to low")
    }
    
    
    // TODO: Upgrade acknowledgement tests
}
