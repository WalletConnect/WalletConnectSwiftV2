import XCTest
import WalletConnectUtils
@testable import TestingUtils
import WalletConnectKMS
@testable import WalletConnectSign

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
        let logger = ConsoleLoggerMock()
        engine = SessionEngine(
            networkingInteractor: networkingInteractor,
            kms: cryptoMock,
            pairingStore: WCPairingStorageMock(),
            sessionStore: storageMock,
            sessionToPairingTopic: CodableStore<String>(defaults: RuntimeKeyValueStorage(), identifier: ""),
            logger: logger,
            topicGenerator: topicGenerator.getTopic)
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
        networkingInteractor.responsePublisherSubject.send(response)

        XCTAssertNil(storageMock.getSession(forTopic: session.topic), "Responder must remove session")
        XCTAssertTrue(networkingInteractor.didUnsubscribe(to: session.topic), "Responder must unsubscribe topic B")
        XCTAssertFalse(cryptoMock.hasAgreementSecret(for: session.topic), "Responder must remove agreement secret")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: session.self.publicKey!), "Responder must remove private key")
    }
}
