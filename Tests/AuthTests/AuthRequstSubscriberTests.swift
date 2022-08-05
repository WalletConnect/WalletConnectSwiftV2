import Foundation
import XCTest
@testable import Auth
import WalletConnectUtils
@testable import WalletConnectKMS
@testable import TestingUtils
import JSONRPC

class AuthRequstSubscriberTests: XCTestCase {
    var networkingInteractor: NetworkingInteractorMock!
    var sut: AuthRequestSubscriber!
    var messageFormatter: SIWEMessageFormatterMock!
    let defaultTimeout: TimeInterval = 0.01

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        messageFormatter = SIWEMessageFormatterMock()
        sut = AuthRequestSubscriber(networkingInteractor: networkingInteractor,
                                   logger: ConsoleLoggerMock(),
                                   messageFormatter: messageFormatter)
    }

    func testSubscribeRequest() {
        let expectedMessage = "Expected Message"
        let expectedRequestId: RPCID = RPCID(1234)
        let messageExpectation = expectation(description: "receives formatted message")
        messageFormatter.formattedMessage = expectedMessage
        var messageId: RPCID!
        var message: String!
        sut.onRequest = { id, formattedMessage in
            messageId = id
            message = formattedMessage
            messageExpectation.fulfill()
        }

        networkingInteractor.requestPublisherSubject.send(RequestSubscriptionPayload.stub(id: expectedRequestId))

        wait(for: [messageExpectation], timeout: defaultTimeout)
        XCTAssertEqual(message, expectedMessage)
        XCTAssertEqual(messageId, expectedRequestId)
    }
}
