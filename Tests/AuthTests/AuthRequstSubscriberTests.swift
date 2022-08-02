import Foundation
import XCTest
@testable import Auth
import WalletConnectUtils
@testable import WalletConnectKMS
@testable import TestingUtils
import JSONRPC

class AuthRequstSubscriberTests: XCTestCase {
    var networkingInteractor: NetworkingInteractorMock!
    var sut: AuthRequstSubscriber!
    var messageFormatter: SIWEMessageFormatterMock!
    let defaultTimeout: TimeInterval = 0.01

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        messageFormatter = SIWEMessageFormatterMock()
        sut = AuthRequstSubscriber(networkingInteractor: networkingInteractor,
                                   logger: ConsoleLoggerMock(),
                                   messageFormatter: messageFormatter)
    }

    func testSubscribeRequest() {
        let expectedMessage = "Expected Message"
        let expectedRequestId: Int64 = 12345
        let messageExpectation = expectation(description: "receives formatted message")
        messageFormatter.formattedMessage = expectedMessage
        var messageId: Int64!
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

extension RequestSubscriptionPayload {
    static func stub(id: Int64) -> RequestSubscriptionPayload {
        let appMetadata = AppMetadata(name: "", description: "", url: "", icons: [])
        let requester = AuthRequestParams.Requester(publicKey: "", metadata: appMetadata)
        let issueAt = ISO8601DateFormatter().string(from: Date())
        let payload = AuthPayload(requestParams: RequestParams.stub(), iat: issueAt)
        let params = AuthRequestParams(requester: requester, payloadParams: payload)
        let request = RPCRequest(method: "wc_authRequest", params: params, id: id)
        return RequestSubscriptionPayload(topic: "", request: request)
    }
}

extension RequestParams {
    static func stub() -> RequestParams {
        return RequestParams(domain: "", chainId: "", nonce: "", aud: "", nbf: nil, exp: nil, statement: nil, requestId: nil, resources: nil)
    }
}
