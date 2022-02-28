import XCTest
import WalletConnectUtils
import TestingUtils
import WalletConnectKMS
@testable import WalletConnect

extension Collection where Self.Element == String {
    func toAccountSet() -> Set<Account> {
        Set(self.map { Account($0)! })
    }
}

// TODO: Remove `setupEngine()` calls now that setting controller flag is not needed anymore
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
        metadata = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
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
    
    func testPropose() {
        setupEngine()
        let pairing = Pairing.stub()
        let topicA = pairing.topic
        let permissions = SessionPermissions.stub()
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
        
        engine.proposeSession(pairing: pairing, permissions: permissions, relay: relayOptions)

        guard let publishTopic = relayMock.requests.first?.topic,
              let proposal = relayMock.requests.first?.request.sessionProposal else {
            XCTFail("Proposer must publish a proposal request."); return
        }
        XCTAssert(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must store the private key matching the public key sent through the proposal.")
        XCTAssert(storageMock.hasPendingProposedSession(on: topicA), "The engine must store a pending session on proposed state.")
        XCTAssertEqual(publishTopic, topicA)
    }
//
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
//        let relayOptions = RelayProtocolOptions(protocol: "", params: nil)
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
        setupEngine()
        let updateAccounts = ["std:0:0"]
        let session = SessionSequence.stubSettled(isSelfController: true)
        storageMock.setSequence(session)
        try engine.update(topic: session.topic, accounts: updateAccounts.toAccountSet())
        XCTAssertTrue(relayMock.didCallRequest)
    }
    
    func testUpdateErrorIfNonController() {
        setupEngine()
        let updateAccounts = ["std:0:0"]
        let session = SessionSequence.stubSettled(isSelfController: false)
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.update(topic: session.topic, accounts: updateAccounts.toAccountSet()), "Update must fail if called by a non-controller.")
    }
    
    func testUpdateErrorSessionNotFound() {
        setupEngine()
        let updateAccounts = ["std:0:0"]
        XCTAssertThrowsError(try engine.update(topic: "", accounts: updateAccounts.toAccountSet()), "Update must fail if there is no session matching the target topic.")
    }
    
    func testUpdateErrorSessionNotSettled() {
        setupEngine()
        let updateAccounts = ["std:0:0"]
        let session = SessionSequence.stubPreSettled()
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.update(topic: session.topic, accounts: updateAccounts.toAccountSet()), "Update must fail if session is not on settled state.")
    }
    
    // MARK: - Update peer response tests
    
    func testUpdatePeerSuccess() {
        setupEngine()
        let session = SessionSequence.stubSettled(isSelfController: false)
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic))
        XCTAssertTrue(relayMock.didRespondSuccess)
    }
    
    func testUpdatePeerErrorAccountInvalid() {
        setupEngine()
        let session = SessionSequence.stubSettled(isSelfController: false)
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic, accounts: ["0"]))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1003)
    }
    
    func testUpdatePeerErrorNoSession() {
        setupEngine()
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: ""))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1301)
    }
    
    func testUpdatePeerErrorSessionNotSettled() {
        setupEngine()
        let session = SessionSequence.stubPreSettled(isSelfController: false) // Session is not fully settled
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3003)
    }
    
    func testUpdatePeerErrorUnauthorized() {
        setupEngine()
        let session = SessionSequence.stubSettled(isSelfController: true) // Peer is not a controller
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpdate(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3003)
    }
    // TODO: Update acknowledgement tests
    
    // MARK: - Upgrade call tests
    
    func testUpgradeSuccess() throws {
        setupEngine()
        let permissions = Session.Permissions.stub()
        let session = SessionSequence.stubSettled(isSelfController: true)
        storageMock.setSequence(session)
        try engine.upgrade(topic: session.topic, permissions: permissions)
        XCTAssertTrue(relayMock.didCallRequest)
        // TODO: Check permissions on stored session
    }
    
    func testUpgradeErrorSessionNotFound() {
        setupEngine()
        XCTAssertThrowsError(try engine.upgrade(topic: "", permissions: Session.Permissions.stub())) { error in
            XCTAssertTrue(error.isNoSessionMatchingTopicError)
        }
    }
    
    func testUpgradeErrorSessionNotSettled() {
        setupEngine()
        let session = SessionSequence.stubPreSettled()
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.upgrade(topic: session.topic, permissions: Session.Permissions.stub())) { error in
            XCTAssertTrue(error.isSessionNotSettledError)
        }
    }
    
    func testUpgradeErrorInvalidPermissions() {
        setupEngine()
        let session = SessionSequence.stubSettled(isSelfController: true)
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
        setupEngine()
        let session = SessionSequence.stubSettled(isSelfController: false)
        storageMock.setSequence(session)
        XCTAssertThrowsError(try engine.upgrade(topic: session.topic, permissions: Session.Permissions.stub())) { error in
            XCTAssertTrue(error.isUnauthorizedNonControllerCallError)
        }
    }
    
    // MARK: - Upgrade peer response tests
    
    func testUpgradePeerSuccess() {
        setupEngine()
        var didCallbackUpgrade = false
        let session = SessionSequence.stubSettled(isSelfController: false)
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
        setupEngine()
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpgrade(topic: ""))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1301)
    }
    
    func testUpgradePeerErrorSessionNotSettled() {
        setupEngine()
        let session = SessionSequence.stubPreSettled(isSelfController: false) // Session is not fully settled
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpgrade(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3004)
    }
    
    func testUpgradePeerErrorUnauthorized() {
        setupEngine()
        let session = SessionSequence.stubSettled(isSelfController: true) // Peer is not a controller
        storageMock.setSequence(session)
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubUpgrade(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3004)
    }
    
    // MARK: - Session Extend on extending client
    
    func testExtendSuccess() {
        setupEngine()
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stubSettled(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 2*Time.day
        XCTAssertNoThrow(try engine.extend(topic: session.topic, ttl: twoDays))
        let extendedSession = engine.getSettledSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(extendedSession.expiryDate.timeIntervalSinceReferenceDate, TimeTraveler.dateByAdding(days: 2).timeIntervalSinceReferenceDate, accuracy: 1)
    }
    
    func testExtendSessionNotSettled() {
        setupEngine()
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stubPreSettled(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 2*Time.day
        XCTAssertThrowsError(try engine.extend(topic: session.topic, ttl: twoDays))
    }
    
    func testExtendOnNonControllerClient() {
        setupEngine()
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stubSettled(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 2*Time.day
        XCTAssertThrowsError(try engine.extend(topic: session.topic, ttl: twoDays))
    }
    
    func testExtendTtlTooHigh() {
        setupEngine()
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stubSettled(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let tenDays = 10*Time.day
        XCTAssertThrowsError(try engine.extend(topic: session.topic, ttl: tenDays))
    }
    
    func testExtendTtlTooLow() {
        setupEngine()
        let dayAfterTommorow = TimeTraveler.dateByAdding(days: 2)
        let session = SessionSequence.stubSettled(isSelfController: true, expiryDate: dayAfterTommorow)
        storageMock.setSequence(session)
        let oneDay = 1*Time.day
        XCTAssertThrowsError(try engine.extend(topic: session.topic, ttl: oneDay))
    }
    
    //MARK: - Handle Session Extend call from peer
    
    func testPeerExtendSuccess() {
        setupEngine()
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stubSettled(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 2*Time.day
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubExtend(topic: session.topic, ttl: twoDays))
        let extendedSession = engine.getSettledSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(extendedSession.expiryDate.timeIntervalSinceReferenceDate, TimeTraveler.dateByAdding(days: 2).timeIntervalSinceReferenceDate, accuracy: 1)
    }
    
    func testPeerExtendUnauthorized() {
        setupEngine()
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stubSettled(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 2*Time.day
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubExtend(topic: session.topic, ttl: twoDays))
        let potentiallyExtendedSession = engine.getSettledSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentiallyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, "expiry date has been extended for peer non controller request ")
    }
    
    func testPeerExtendTtlTooHigh() {
        setupEngine()
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = SessionSequence.stubSettled(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 10*Time.day
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubExtend(topic: session.topic, ttl: twoDays))
        let potentaillyExtendedSession = engine.getSettledSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentaillyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, "expiry date has been extended despite ttl to high")
    }
    
    func testPeerExtendTtlTooLow() {
        setupEngine()
        let tomorrow = TimeTraveler.dateByAdding(days: 2)
        let session = SessionSequence.stubSettled(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSequence(session)
        let twoDays = 1*Time.day
        subscriberMock.onReceivePayload?(WCRequestSubscriptionPayload.stubExtend(topic: session.topic, ttl: twoDays))
        let potentaillyExtendedSession = engine.getSettledSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentaillyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, "expiry date has been extended despite ttl to low")
    }
    
    
    // TODO: Upgrade acknowledgement tests
}
