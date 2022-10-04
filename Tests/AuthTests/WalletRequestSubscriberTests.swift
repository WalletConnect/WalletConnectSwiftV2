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
                                      messageFormatter: messageFormatter, address: "",
                                      walletErrorResponder: walletErrorResponder,
                                      pairingRegisterer: pairingRegisterer)
    }

    func testSubscribeRequest() {
        let expectedMessage = "Expected Message"
        let expectedRequestId: RPCID = RPCID(1234)
        let messageExpectation = expectation(description: "receives formatted message")
        messageFormatter.formattedMessage = expectedMessage
        var messageId: RPCID!
        var message: String!
        sut.onRequest = { request in
            messageId = request.id
            message = request.message
            messageExpectation.fulfill()
        }
        
        let payload = RequestSubscriptionPayload<AuthRequestParams>(id: expectedRequestId, topic: "123", request: AuthRequestParams.stub(id: expectedRequestId))

        pairingRegisterer.subject.send(payload)

        wait(for: [messageExpectation], timeout: defaultTimeout)
        XCTAssertTrue(pairingRegisterer.isActivateCalled)
        XCTAssertEqual(message, expectedMessage)
        XCTAssertEqual(messageId, expectedRequestId)
    }
}
