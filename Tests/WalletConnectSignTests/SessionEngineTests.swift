import XCTest
@testable import WalletConnectSign
@testable import WalletConnectUtils
@testable import TestingUtils

final class SessionEngineTests: XCTestCase {

    var networkingInteractor: NetworkingInteractorMock!
    var sessionStorage: WCSessionStorageMock!
    var verifyContextStore: CodableStore<VerifyContext>!
    var rpcHistory: RPCHistory!
    var engine: SessionEngine!

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        sessionStorage = WCSessionStorageMock()
        let defaults = RuntimeKeyValueStorage()
        rpcHistory = RPCHistory(
            keyValueStore: .init(
                defaults: defaults,
                identifier: ""
            )
        )
        verifyContextStore = CodableStore<VerifyContext>(defaults: RuntimeKeyValueStorage(), identifier: "")
        let historyService = HistoryService(
            history: rpcHistory,
            verifyContextStore: verifyContextStore
        )
        engine = SessionEngine(
            networkingInteractor: networkingInteractor,
            historyService: historyService,
            verifyContextStore: verifyContextStore,
            kms: KeyManagementServiceMock(),
            sessionStore: sessionStorage,
            logger: ConsoleLoggerMock(),
            sessionRequestsProvider: SessionRequestsProvider(
                historyService: historyService),
            invalidRequestsSanitiser: InvalidRequestsSanitiser(historyService: historyService, history: rpcHistory)
        )
    }

    func testErrorOnRequestExpiry() {
        let expectation = expectation(description: "TestErrorOnRequestExpiry")

        sessionStorage.setSession(WCSession.stub(
            topic: "topic",
            namespaces: SessionNamespace.stubDictionary()
        ))

        networkingInteractor.onRespondError = { code in
            XCTAssertEqual(code, 8000)
            expectation.fulfill()
        }

        let request = RPCRequest.stubRequest(
            method: "method",
            chainId: Blockchain("eip155:1")!,
            expiry: UInt64(Date().timeIntervalSince1970)
        )

        networkingInteractor.requestPublisherSubject.send(("topic", request, Data(), Date(), "", "", nil))

        wait(for: [expectation], timeout: 0.5)
    }
    
    func testRemovePendingRequestsOnSessionExpiration() {
        let expectation = expectation(
            description: "Remove pending requests on session expiration"
        )
        
        let historyService = MockHistoryService()
        
        engine = SessionEngine(
            networkingInteractor: networkingInteractor,
            historyService: historyService,
            verifyContextStore: verifyContextStore,
            kms: KeyManagementServiceMock(),
            sessionStore: sessionStorage,
            logger: ConsoleLoggerMock(),
            sessionRequestsProvider: SessionRequestsProvider(
                historyService: historyService),
            invalidRequestsSanitiser: InvalidRequestsSanitiser(
                historyService: historyService,
                history: rpcHistory
            )
        )
        
        let expectedTopic = "topic"

        let session = WCSession.stub(
            topic: expectedTopic,
            namespaces: SessionNamespace.stubDictionary()
        )
        
        sessionStorage.setSession(session)
        
        historyService.removePendingRequestCalled = { topic in
            XCTAssertEqual(topic, expectedTopic)
            expectation.fulfill()
        }
        
        sessionStorage.onSessionExpiration!(session)
        
        wait(for: [expectation], timeout: 0.5)
    }
}
