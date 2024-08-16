import XCTest
import Combine
import JSONRPC
import WalletConnectNetworking
@testable import WalletConnectPairing
@testable import WalletConnectSign
@testable import TestingUtils
@testable import WalletConnectKMS
@testable import WalletConnectUtils

final class ApproveEngineTests: XCTestCase {

    var engine: ApproveEngine!
    var metadata: AppMetadata!
    var networkingInteractor: NetworkingInteractorMock!
    var cryptoMock: KeyManagementServiceMock!
    var pairingStorageMock: WCPairingStorageMock!
    var sessionStorageMock: WCSessionStorageMock!
    var pairingRegisterer: PairingRegistererMock<SessionProposal>!
    var proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>!
    var verifyContextStore: CodableStore<VerifyContext>!
    var sessionTopicToProposal: CodableStore<Session.Proposal>!

    var publishers = Set<AnyCancellable>()

    override func setUp() {
        metadata = AppMetadata.stub()
        networkingInteractor = NetworkingInteractorMock()
        cryptoMock = KeyManagementServiceMock()
        pairingStorageMock = WCPairingStorageMock()
        sessionStorageMock = WCSessionStorageMock()
        pairingRegisterer = PairingRegistererMock()
        proposalPayloadsStore = CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>(defaults: RuntimeKeyValueStorage(), identifier: "")
        verifyContextStore = CodableStore<VerifyContext>(defaults: RuntimeKeyValueStorage(), identifier: "")
        sessionTopicToProposal = CodableStore<Session.Proposal>(defaults: RuntimeKeyValueStorage(), identifier: "")
        let history = RPCHistory(
            keyValueStore: .init(
                defaults: RuntimeKeyValueStorage(),
                identifier: ""
            )
        )
        engine = ApproveEngine(
            networkingInteractor: networkingInteractor,
            proposalPayloadsStore: proposalPayloadsStore,
            verifyContextStore: verifyContextStore,
            sessionTopicToProposal: sessionTopicToProposal,
            pairingRegisterer: pairingRegisterer,
            metadata: metadata,
            kms: cryptoMock,
            logger: ConsoleLoggerMock(),
            pairingStore: pairingStorageMock,
            sessionStore: sessionStorageMock,
            verifyClient: VerifyClientMock(),
            rpcHistory: history,
            authRequestSubscribersTracking: AuthRequestSubscribersTracking(logger: ConsoleLoggerMock()),
            eventsClient: MockEventsClient()
        )
    }

    override func tearDown() {
        networkingInteractor = nil
        metadata = nil
        cryptoMock = nil
        pairingRegisterer = nil
        pairingStorageMock = nil
        engine = nil
    }

    func testApproveProposal() async throws {
        // Client receives a proposal
        let topicA = String.generateTopic()
        let pairing = WCPairing.stub(expiryDate: Date(timeIntervalSinceNow: 10000), topic: topicA)
        pairingStorageMock.setPairing(pairing)
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)
        pairingRegisterer.subject.send(RequestSubscriptionPayload(id: RPCID("id"), topic: topicA, request: proposal, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil, encryptedMessage: "", attestation: nil))

        _ = try await engine.approveProposal(proposerPubKey: proposal.proposer.publicKey, validating: SessionNamespace.stubDictionary())

        let topicB = networkingInteractor.subscriptions.last!

        XCTAssertTrue(networkingInteractor.didCallSubscribe)
        XCTAssert(cryptoMock.hasAgreementSecret(for: topicB), "Responder must store agreement key for topic B")
        XCTAssertEqual(networkingInteractor.didRespondOnTopic!, topicA, "Responder must respond on topic A")
        XCTAssertTrue(sessionStorageMock.hasSession(forTopic: topicB), "Responder must persist session on topic B")
    }

    func testReceiveProposal() {
        let pairing = WCPairing.stub()
        let topicA = pairing.topic
        pairingStorageMock.setPairing(pairing)
        var sessionProposed = false
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)

        engine.onSessionProposal = { _, _ in
            sessionProposed = true
        }

        pairingRegisterer.subject.send(RequestSubscriptionPayload(id: RPCID("id"), topic: topicA, request: proposal, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil, encryptedMessage: "", attestation: nil))
        XCTAssertNotNil(try! proposalPayloadsStore.get(key: proposal.proposer.publicKey), "Proposer must store proposal payload")
        XCTAssertTrue(sessionProposed)
    }

    func testSessionSettle() async throws {
        let agreementKeys = AgreementKeys.stub()
        let topicB = String.generateTopic()
        cryptoMock.setAgreementSecret(agreementKeys, topic: topicB)
        let proposal = SessionProposal.stub(proposerPubKey: AgreementPrivateKey().publicKey.hexRepresentation)
        _ = try await engine.settle(topic: topicB, proposal: proposal, namespaces: SessionNamespace.stubDictionary(), pairingTopic: "")
        XCTAssert(networkingInteractor.didSubscribe(to: topicB), "Responder must subscribe for topic B")
        XCTAssertTrue(networkingInteractor.didCallRequest, "Responder must send session settle payload on topic B")
    }

    func testHandleSessionSettle() {
        let sessionTopic = String.generateTopic()
        cryptoMock.setAgreementSecret(AgreementKeys.stub(), topic: sessionTopic)
        var didCallBackOnSessionApproved = false
        engine.onSessionSettle = { _ in
            didCallBackOnSessionApproved = true
        }
        sessionTopicToProposal.set(SessionProposal.stub().publicRepresentation(pairingTopic: ""), forKey: sessionTopic)
        networkingInteractor.requestPublisherSubject.send((sessionTopic, RPCRequest.stubSettle(), Data(), Date(), "", "", nil))

        usleep(100)

        XCTAssertTrue(sessionStorageMock.getSession(forTopic: sessionTopic)!.acknowledged, "Proposer must store acknowledged session on topic B")
        XCTAssertTrue(networkingInteractor.didRespondSuccess, "Proposer must send acknowledge on settle request")
        XCTAssertTrue(didCallBackOnSessionApproved, "Proposer's engine must call back with session")
    }

    func testHandleSessionSettleAcknowledge() {
        let session = WCSession.stub(isSelfController: true, acknowledged: false)
        sessionStorageMock.setSession(session)

        let request = RPCRequest(method: SessionSettleProtocolMethod().method, params: SessionType.SettleParams.stub())
        let response = RPCResponse(matchingRequest: request, result: RPCResult.response(AnyCodable(true)))

        networkingInteractor.responsePublisherSubject.send((session.topic, request, response, Date(), nil))

        XCTAssertTrue(sessionStorageMock.getSession(forTopic: session.topic)!.acknowledged, "Responder must acknowledged session")
    }

    func testHandleSessionSettleError() {
        let privateKey = AgreementPrivateKey()
        let session = WCSession.stub(isSelfController: false, selfPrivateKey: privateKey, acknowledged: false)
        sessionStorageMock.setSession(session)
        cryptoMock.setAgreementSecret(AgreementKeys.stub(), topic: session.topic)
        try! cryptoMock.setPrivateKey(privateKey)

        let request = RPCRequest(method: SessionSettleProtocolMethod().method, params: SessionType.SettleParams.stub())
        let response = RPCResponse.stubError(forRequest: request)

        networkingInteractor.responsePublisherSubject.send((session.topic, request, response, Date(), nil))

        XCTAssertNil(sessionStorageMock.getSession(forTopic: session.topic), "Responder must remove session")
        XCTAssertTrue(networkingInteractor.didUnsubscribe(to: session.topic), "Responder must unsubscribe topic B")
        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: session.topic), "Responder must remove agreement secret")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: session.self.publicKey!), "Responder must remove private key")
    }
    
    func testVerifyContextStorageAdd() {
        let proposalReceivedExpectation = expectation(description: "Wallet expects to receive a proposal")
        
        let pairing = WCPairing.stub()
        let topicA = pairing.topic
        pairingStorageMock.setPairing(pairing)
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)

        engine.onSessionProposal = { _, _ in
            proposalReceivedExpectation.fulfill()
        }
        pairingRegisterer.subject.send(RequestSubscriptionPayload(id: RPCID("id"), topic: topicA, request: proposal, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil, encryptedMessage: "", attestation: nil))

        wait(for: [proposalReceivedExpectation], timeout: 0.1)
        
        XCTAssertTrue(verifyContextStore.getAll().count == 1)
    }
    
    func testVerifyContextStorageRemoveOnApprove() async throws {
        let proposalReceivedExpectation = expectation(description: "Wallet expects to receive a proposal")
        
        let pairing = WCPairing.stub()
        let topicA = pairing.topic
        pairingStorageMock.setPairing(pairing)
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)
        
        engine.onSessionProposal = { _, _ in
            proposalReceivedExpectation.fulfill()
        }
        pairingRegisterer.subject.send(RequestSubscriptionPayload(id: RPCID("id"), topic: topicA, request: proposal, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil, encryptedMessage: "", attestation: nil))

        wait(for: [proposalReceivedExpectation], timeout: 0.1)
        
        XCTAssertTrue(verifyContextStore.getAll().count == 1)
        
        _ = try await engine.approveProposal(proposerPubKey: proposal.proposer.publicKey, validating: SessionNamespace.stubDictionary())
        
        XCTAssertTrue(verifyContextStore.getAll().isEmpty)
    }
    
    func testVerifyContextStorageRemoveOnReject() async throws {
        let proposalReceivedExpectation = expectation(description: "Wallet expects to receive a proposal")
        
        let pairing = WCPairing.stub()
        let topicA = pairing.topic
        pairingStorageMock.setPairing(pairing)
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)
        
        engine.onSessionProposal = { _, _ in
            proposalReceivedExpectation.fulfill()
        }
        pairingRegisterer.subject.send(RequestSubscriptionPayload(id: RPCID("id"), topic: topicA, request: proposal, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil, encryptedMessage: "", attestation: nil))
        
        wait(for: [proposalReceivedExpectation], timeout: 0.1)
        
        XCTAssertTrue(verifyContextStore.getAll().count == 1)
        
        try await engine.reject(proposerPubKey: proposal.proposer.publicKey, reason: .userRejected)
        
        XCTAssertTrue(verifyContextStore.getAll().isEmpty)
    }
}
