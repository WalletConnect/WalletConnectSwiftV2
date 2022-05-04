
import Foundation
import Combine
import XCTest
import WalletConnectUtils
@testable import TestingUtils
@testable import WalletConnect

class WalletConnectRelayTests: XCTestCase {
    var wcRelay: WalletConnectRelay!
    var networkRelayer: MockedNetworkRelayer!
    var serializer: SerializerMock!

    private var publishers = [AnyCancellable]()

    override func setUp() {
        let logger = ConsoleLoggerMock()
        serializer = SerializerMock()
        networkRelayer = MockedNetworkRelayer()
        wcRelay = WalletConnectRelay(networkRelayer: networkRelayer, serializer: serializer, logger: logger, jsonRpcHistory: JsonRpcHistory(logger: logger, keyValueStore: KeyValueStore<WalletConnect.JsonRpcRecord>(defaults: RuntimeKeyValueStorage(), identifier: "")))
    }

    override func tearDown() {
        wcRelay = nil
        networkRelayer = nil
        serializer = nil
    }
    
    func testNotifiesOnEncryptedWCJsonRpcRequest() {
        let requestExpectation = expectation(description: "notifies with request")
        let topic = "fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a"
        wcRelay.wcRequestPublisher.sink { (request) in
            requestExpectation.fulfill()
        }.store(in: &publishers)
        serializer.deserialized = request
        networkRelayer.onMessage?(topic, testPayload)
        waitForExpectations(timeout: 1.001, handler: nil)
    }

    func testPromptOnSessionRequest() async {
        let topic = "fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a"
        let request = getWCSessionRequest()
        networkRelayer.prompt = false
        try! await wcRelay.request(topic: topic, payload: request)
        XCTAssertTrue(networkRelayer.prompt)
    }
}

extension WalletConnectRelayTests {
    func getWCSessionResponse() -> JSONRPCResponse<AnyCodable> {
        let result = AnyCodable("")
        return JSONRPCResponse<AnyCodable>(id: 123456, result: result)
    }
    
    func getWCSessionRequest() -> WCRequest {
        let wcRequestId: Int64 = 123456
        let sessionRequestParams = SessionType.RequestParams(request: SessionType.RequestParams.Request(method: "method", params: AnyCodable("params")), chainId: Blockchain("eip155:1")!)
        let params = WCRequest.Params.sessionRequest(sessionRequestParams)
        let wcRequest = WCRequest(id: wcRequestId, method: WCRequest.Method.sessionRequest, params: params)
        return wcRequest
    }
}

fileprivate let testPayload =
"""
{
   "id":1630300527198334,
   "jsonrpc":"2.0",
   "method":"waku_subscription",
   "params":{
      "id":"0847f4e1dd19cf03a43dc7525f39896b630e9da33e4683c8efbc92ea671b5e07",
      "data":{
         "topic":"fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a",
         "message":"7b226964223a313633303330303532383030302c226a736f6e727063223a22322e30222c22726573756c74223a747275657d"
      }
   }
}
"""
//TODO - change for different request
fileprivate let request = WCRequest(id: 1, jsonrpc: "2.0", method: .pairingPing, params: WCRequest.Params.pairingPing(PairingType.PingParams()))
