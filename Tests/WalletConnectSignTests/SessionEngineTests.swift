import XCTest
@testable import WalletConnectSign
@testable import WalletConnectUtils
@testable import TestingUtils

final class SessionEngineTests: XCTestCase {

    var networkingInteractor: NetworkingInteractorMock!
    var sessionStorage: WCSessionStorageMock!
    var engine: SessionEngine!

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        sessionStorage = WCSessionStorageMock()
        engine = SessionEngine(
            networkingInteractor: networkingInteractor,
            historyService: HistoryService(
                history: RPCHistory(
                    keyValueStore: .init(
                        defaults: RuntimeKeyValueStorage(),
                        identifier: ""
                    )
                )
            ),
            kms: KeyManagementServiceMock(),
            sessionStore: sessionStorage,
            logger: ConsoleLoggerMock()
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

        networkingInteractor.requestPublisherSubject.send(("topic", request, Date()))

        wait(for: [expectation], timeout: 0.5)
    }
}
