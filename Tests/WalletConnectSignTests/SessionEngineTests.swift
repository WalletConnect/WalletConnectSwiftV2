import XCTest
@testable import WalletConnectSign
@testable import WalletConnectUtils
@testable import TestingUtils

final class SessionEngineTests: XCTestCase {

    var networkingInteractor: NetworkingInteractorMock!
    var sessionStorage: WCSessionStorageMock!
    var verifyContextStore: CodableStore<VerifyContext>!
    var engine: SessionEngine!
    var rpcHistory: RPCHistory!
    var historyService: HistoryService!
    var sessionRequestsProvider: SessionRequestsProvider!

    override func setUp() {
        rpcHistory = RPCHistory(
            keyValueStore: .init(
                defaults: RuntimeKeyValueStorage(),
                identifier: ""
            )
        )
        historyService = HistoryService(
            history: rpcHistory,
            verifyContextStore: verifyContextStore
        )
        sessionRequestsProvider = SessionRequestsProvider(historyService: historyService)
        networkingInteractor = NetworkingInteractorMock()
        sessionStorage = WCSessionStorageMock()
        verifyContextStore = CodableStore<VerifyContext>(defaults: RuntimeKeyValueStorage(), identifier: "")
        engine = SessionEngine(
            networkingInteractor: networkingInteractor,
            historyService: historyService,
            verifyContextStore: verifyContextStore,
            verifyClient: VerifyClientMock(),
            kms: KeyManagementServiceMock(),
            sessionStore: sessionStorage,
            logger: ConsoleLoggerMock(),
            sessionRequestsProvider: sessionRequestsProvider
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

        networkingInteractor.requestPublisherSubject.send(("topic", request, Data(), Date(), ""))

        wait(for: [expectation], timeout: 0.5)
    }
}

