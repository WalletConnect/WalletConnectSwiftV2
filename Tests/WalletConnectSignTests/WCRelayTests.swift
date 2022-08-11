import Foundation
import Combine
import XCTest
import WalletConnectUtils
import WalletConnectPairing
@testable import TestingUtils
@testable import WalletConnectSign

class NetworkingInteractorTests: XCTestCase {
    var networkingInteractor: NetworkInteractor!
    var relayClient: MockedRelayClient!
    var serializer: SerializerMock!

    private var publishers = [AnyCancellable]()

    override func setUp() {
        let logger = ConsoleLoggerMock()
        serializer = SerializerMock()
        relayClient = MockedRelayClient()
        networkingInteractor = NetworkInteractor(relayClient: relayClient, serializer: serializer, logger: logger, jsonRpcHistory: JsonRpcHistory(logger: logger, keyValueStore: CodableStore<WalletConnectSign.JsonRpcRecord>(defaults: RuntimeKeyValueStorage(), identifier: "")))
    }

    override func tearDown() {
        networkingInteractor = nil
        relayClient = nil
        serializer = nil
    }

    func testNotifiesOnEncryptedWCJsonRpcRequest() {
        let requestExpectation = expectation(description: "notifies with request")
        let topic = "fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a"
        networkingInteractor.wcRequestPublisher.sink { (_) in
            requestExpectation.fulfill()
        }.store(in: &publishers)
        serializer.deserialized = request
        relayClient.onMessage?(topic, testPayload)
        waitForExpectations(timeout: 1.001, handler: nil)
    }

    func testPromptOnSessionRequest() async {
        let topic = "fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a"
        let method = getWCSessionMethod()
        relayClient.prompt = false
        try! await networkingInteractor.request(topic: topic, payload: method.asRequest())
        XCTAssertTrue(relayClient.prompt)
    }
}

extension NetworkingInteractorTests {
    func getWCSessionMethod() -> WCMethod {
        let sessionRequestParams = SessionType.RequestParams(request: SessionType.RequestParams.Request(method: "method", params: AnyCodable("params")), chainId: Blockchain("eip155:1")!)
        return .wcSessionRequest(sessionRequestParams)
    }
}

private let testPayload =
"""
{
   "id":1630300527198334,
   "jsonrpc":"2.0",
   "method":"irn_subscription",
   "params":{
      "id":"0847f4e1dd19cf03a43dc7525f39896b630e9da33e4683c8efbc92ea671b5e07",
      "data":{
         "topic":"fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a",
         "message":"7b226964223a313633303330303532383030302c226a736f6e727063223a22322e30222c22726573756c74223a747275657d"
      }
   }
}
"""
// TODO - change for different request
private let request = WCRequest(id: 1, jsonrpc: "2.0", method: .pairingPing, params: WCRequest.Params.pairingPing(PairingType.PingParams()))
