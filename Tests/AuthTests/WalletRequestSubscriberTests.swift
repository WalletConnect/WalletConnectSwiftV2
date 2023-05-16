import Foundation
import XCTest
import JSONRPC
@testable import WalletConnectUtils
@testable import WalletConnectNetworking
@testable import Auth
@testable import WalletConnectKMS
@testable import TestingUtils

class WalletRequestSubscriberTests: XCTestCase {
    var pairingRegisterer: PairingRegistererMock<AuthRequestParams>!
    var sut: WalletRequestSubscriber!
    var messageFormatter: SIWEMessageFormatterMock!

    let defaultTimeout: TimeInterval = 0.01

    override func setUp() {
        let networkingInteractor = NetworkingInteractorMock()
        pairingRegisterer = PairingRegistererMock()
        messageFormatter = SIWEMessageFormatterMock()

        let walletErrorResponder = WalletErrorResponder(networkingInteractor: networkingInteractor, logger: ConsoleLoggerMock(), kms: KeyManagementServiceMock(), rpcHistory: RPCHistory(keyValueStore: CodableStore(defaults: RuntimeKeyValueStorage(), identifier: "")))
        sut = WalletRequestSubscriber(networkingInteractor: networkingInteractor,
                                      logger: ConsoleLoggerMock(),
                                      kms: KeyManagementServiceMock(),
                                      walletErrorResponder: walletErrorResponder,
                                      pairingRegisterer: pairingRegisterer,
                                      verifyClient: nil)
    }

    func testSubscribeRequest() {
        let iat = ISO8601DateFormatter().string(from: Date())
        let expectedPayload = AuthPayload(requestParams: .stub(), iat: iat)
        let expectedRequestId: RPCID = RPCID(1234)
        let messageExpectation = expectation(description: "receives formatted message")

        var requestId: RPCID!
        var requestPayload: AuthPayload!
        sut.onRequest = { result in
            requestId = result.request.id
            requestPayload = result.request.payload
            messageExpectation.fulfill()
        }

        let payload = RequestSubscriptionPayload<AuthRequestParams>(id: expectedRequestId, topic: "123", request: AuthRequestParams.stub(id: expectedRequestId, iat: iat), decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil)

        pairingRegisterer.subject.send(payload)

        wait(for: [messageExpectation], timeout: defaultTimeout)
        XCTAssertTrue(pairingRegisterer.isActivateCalled)
        XCTAssertEqual(requestPayload, expectedPayload)
        XCTAssertEqual(requestId, expectedRequestId)
    }
}
