import XCTest
import Combine
import WalletConnectUtils
import WalletConnectPairing
@testable import WalletConnectSign
@testable import TestingUtils
@testable import WalletConnectKMS

final class ApproveEngineTests: XCTestCase {

    var engine: ApproveEngine!
    var metadata: AppMetadata!
    var networkingInteractor: NetworkingInteractorMock!
    var cryptoMock: KeyManagementServiceMock!
    var pairingStorageMock: WCPairingStorageMock!
    var sessionStorageMock: WCSessionStorageMock!
    var proposalPayloadsStore: CodableStore<WCRequestSubscriptionPayload>!

    var publishers = Set<AnyCancellable>()

    override func setUp() {
        metadata = AppMetadata.stub()
        networkingInteractor = NetworkingInteractorMock()
        cryptoMock = KeyManagementServiceMock()
        pairingStorageMock = WCPairingStorageMock()
        sessionStorageMock = WCSessionStorageMock()
        proposalPayloadsStore = CodableStore<WCRequestSubscriptionPayload>(defaults: RuntimeKeyValueStorage(), identifier: "")
        engine = ApproveEngine(
            networkingInteractor: networkingInteractor,
            proposalPayloadsStore: proposalPayloadsStore,
            sessionToPairingTopic: CodableStore<String>(defaults: RuntimeKeyValueStorage(), identifier: ""),
            metadata: metadata,
            kms: cryptoMock,
            logger: ConsoleLoggerMock(),
            pairingStore: pairingStorageMock,
            sessionStore: sessionStorageMock
        )
    }

    override func tearDown() {
        networkingInteractor = nil
        metadata = nil
        cryptoMock = nil
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
        let request = WCRequest(method: .sessionPropose, params: .sessionPropose(proposal))
        let payload = WCRequestSubscriptionPayload(topic: topicA, wcRequest: request)
        networkingInteractor.wcRequestPublisherSubject.send(payload)

        try await engine.approveProposal(proposerPubKey: proposal.proposer.publicKey, validating: SessionNamespace.stubDictionary())

        let topicB = networkingInteractor.subscriptions.last!

        let extendedPairing = pairingStorageMock.getPairing(forTopic: topicA)!
        XCTAssertTrue(networkingInteractor.didCallSubscribe)
        XCTAssert(cryptoMock.hasAgreementSecret(for: topicB), "Responder must store agreement key for topic B")
        XCTAssertEqual(networkingInteractor.didRespondOnTopic!, topicA, "Responder must respond on topic A")
        XCTAssertEqual(extendedPairing.expiryDate.timeIntervalSince1970, Date(timeIntervalSinceNow: 2_592_000).timeIntervalSince1970, accuracy: 1, "pairing expiry has been extended by 30 days")
    }

    func testReceiveProposal() {
        let pairing = WCPairing.stub()
        let topicA = pairing.topic
        pairingStorageMock.setPairing(pairing)
        var sessionProposed = false
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)
        let request = WCRequest(method: .sessionPropose, params: .sessionPropose(proposal))
        let payload = WCRequestSubscriptionPayload(topic: topicA, wcRequest: request)

        engine.onSessionProposal = { _ in
            sessionProposed = true
        }

        networkingInteractor.wcRequestPublisherSubject.send(payload)
        XCTAssertNotNil(try! proposalPayloadsStore.get(key: proposal.proposer.publicKey), "Proposer must store proposal payload")
        XCTAssertTrue(sessionProposed)
    }

    func testSessionSettle() async throws {
        let agreementKeys = AgreementKeys.stub()
        let topicB = String.generateTopic()
        cryptoMock.setAgreementSecret(agreementKeys, topic: topicB)
        let proposal = SessionProposal.stub(proposerPubKey: AgreementPrivateKey().publicKey.hexRepresentation)
        try await engine.settle(topic: topicB, proposal: proposal, namespaces: SessionNamespace.stubDictionary())
        XCTAssertTrue(sessionStorageMock.hasSession(forTopic: topicB), "Responder must persist session on topic B")
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

        engine.settlingProposal = SessionProposal.stub()
        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubSettle(topic: sessionTopic))

        XCTAssertTrue(sessionStorageMock.getSession(forTopic: sessionTopic)!.acknowledged, "Proposer must store acknowledged session on topic B")
        XCTAssertTrue(networkingInteractor.didRespondSuccess, "Proposer must send acknowledge on settle request")
        XCTAssertTrue(didCallBackOnSessionApproved, "Proposer's engine must call back with session")
    }

    func testHandleSessionSettleAcknowledge() {
        let session = WCSession.stub(isSelfController: true, acknowledged: false)
        sessionStorageMock.setSession(session)

        let settleResponse = JSONRPCResponse(id: 1, result: AnyCodable(true))
        let response = WCResponse(
            topic: session.topic,
            chainId: nil,
            requestMethod: .sessionSettle,
            requestParams: .sessionSettle(SessionType.SettleParams.stub()),
            result: .response(settleResponse))
        networkingInteractor.responsePublisherSubject.send(response)

        XCTAssertTrue(sessionStorageMock.getSession(forTopic: session.topic)!.acknowledged, "Responder must acknowledged session")
    }

    func testHandleSessionSettleError() {
        let privateKey = AgreementPrivateKey()
        let session = WCSession.stub(isSelfController: false, selfPrivateKey: privateKey, acknowledged: false)
        sessionStorageMock.setSession(session)
        cryptoMock.setAgreementSecret(AgreementKeys.stub(), topic: session.topic)
        try! cryptoMock.setPrivateKey(privateKey)

        let response = WCResponse(
            topic: session.topic,
            chainId: nil,
            requestMethod: .sessionSettle,
            requestParams: .sessionSettle(SessionType.SettleParams.stub()),
            result: .error(JSONRPCErrorResponse(id: 1, error: JSONRPCErrorResponse.Error(code: 0, message: ""))))
        networkingInteractor.responsePublisherSubject.send(response)

        XCTAssertNil(sessionStorageMock.getSession(forTopic: session.topic), "Responder must remove session")
        XCTAssertTrue(networkingInteractor.didUnsubscribe(to: session.topic), "Responder must unsubscribe topic B")
        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: session.topic), "Responder must remove agreement secret")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: session.self.publicKey!), "Responder must remove private key")
    }
}
