import XCTest
import WalletConnectUtils
@testable import TestingUtils
import WalletConnectKMS
@testable import WalletConnectAuth

extension Collection where Self.Element == String {
    func toAccountSet() -> Set<Account> {
        Set(self.map { Account($0)! })
    }
}

final class SessionEngineTests: XCTestCase {
    
    var engine: SessionEngine!

    var networkingInteractor: MockedWCRelay!
    var storageMock: WCSessionStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    
    var topicGenerator: TopicGenerator!
    
    var metadata: AppMetadata!
    
    override func setUp() {
        networkingInteractor = MockedWCRelay()
        storageMock = WCSessionStorageMock()
        cryptoMock = KeyManagementServiceMock()
        topicGenerator = TopicGenerator()
        setupEngine()
    }

    override func tearDown() {
        networkingInteractor = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        engine = nil
    }
    
    func setupEngine() {
        metadata = AppMetadata.stub()
        let logger = ConsoleLoggerMock()
        engine = SessionEngine(
            networkingInteractor: networkingInteractor,
            kms: cryptoMock,
            pairingStore: WCPairingStorageMock(),
            sessionStore: storageMock,
            sessionToPairingTopic: KeyValueStore<String>(defaults: RuntimeKeyValueStorage(), identifier: ""),
            metadata: metadata,
            logger: logger,
            topicGenerator: topicGenerator.getTopic)
    }
    
    func testSessionSettle() {
        let agreementKeys = AgreementKeys.stub()
        let topicB = String.generateTopic()
        cryptoMock.setAgreementSecret(agreementKeys, topic: topicB)
        let proposal = SessionProposal.stub(proposerPubKey: AgreementPrivateKey().publicKey.hexRepresentation)
        try? engine.settle(topic: topicB, proposal: proposal, namespaces: SessionNamespace.stubDictionary())
        usleep(100)
        XCTAssertTrue(storageMock.hasSession(forTopic: topicB), "Responder must persist session on topic B")
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
        
        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubSettle(topic: sessionTopic))
        
        
        XCTAssertTrue(storageMock.getSession(forTopic: sessionTopic)!.acknowledged, "Proposer must store acknowledged session on topic B")
        XCTAssertTrue(networkingInteractor.didRespondSuccess, "Proposer must send acknowledge on settle request")
        XCTAssertTrue(didCallBackOnSessionApproved, "Proposer's engine must call back with session")
    }
    
    func testHandleSessionSettleAcknowledge() {
        let session = WCSession.stub(isSelfController: true, acknowledged: false)
        storageMock.setSession(session)
        var didCallBackOnSessionApproved = false
        engine.onSessionSettle = { _ in
            didCallBackOnSessionApproved = true
        }
        
        let settleResponse = JSONRPCResponse(id: 1, result: AnyCodable(true))
        let response = WCResponse(
            topic: session.topic,
            chainId: nil,
            requestMethod: .sessionSettle,
            requestParams: .sessionSettle(SessionType.SettleParams.stub()),
            result: .response(settleResponse))
        networkingInteractor.onResponse?(response)

        XCTAssertTrue(storageMock.getSession(forTopic: session.topic)!.acknowledged, "Responder must acknowledged session")
        XCTAssertTrue(didCallBackOnSessionApproved, "Responder's engine must call back with session")
    }
    
    func testHandleSessionSettleError() {
        let privateKey = AgreementPrivateKey()
        let session = WCSession.stub(isSelfController: false, selfPrivateKey: privateKey, acknowledged: false)
        storageMock.setSession(session)
        cryptoMock.setAgreementSecret(AgreementKeys.stub(), topic: session.topic)
        try! cryptoMock.setPrivateKey(privateKey)

        let response = WCResponse(
            topic: session.topic,
            chainId: nil,
            requestMethod: .sessionSettle,
            requestParams: .sessionSettle(SessionType.SettleParams.stub()),
            result: .error(JSONRPCErrorResponse(id: 1, error: JSONRPCErrorResponse.Error(code: 0, message: ""))))
        networkingInteractor.onResponse?(response)

        XCTAssertNil(storageMock.getSession(forTopic: session.topic), "Responder must remove session")
        XCTAssertTrue(networkingInteractor.didUnsubscribe(to: session.topic), "Responder must unsubscribe topic B")
        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: session.topic), "Responder must remove agreement secret")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: session.self.publicKey!), "Responder must remove private key")
    }
}
