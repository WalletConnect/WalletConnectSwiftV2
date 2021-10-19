
import Foundation
import Combine
import XCTest
@testable import WalletConnect

class WalletConnectRelayTests: XCTestCase {
    var wcRelay: WalletConnectRelay!
    var networkRelayer: MockedNetworkRelayer!
    var serialiser: MockedJSONRPCSerialiser!
    var crypto: Crypto!

    private var publishers = [AnyCancellable]()

    override func setUp() {
        let logger = ConsoleLogger()
        serialiser = MockedJSONRPCSerialiser()
        networkRelayer = MockedNetworkRelayer()
        crypto = Crypto(keychain: DictionaryKeychain())
        wcRelay = WalletConnectRelay(networkRelayer: networkRelayer, jsonRpcSerialiser: serialiser, crypto: crypto, logger: logger)
    }

    override func tearDown() {
        wcRelay = nil
        networkRelayer = nil
        serialiser = nil
    }
    
    func testNotifiesOnEncryptedWCJsonRpcRequest() {
        let requestExpectation = expectation(description: "notifies with request")
        let topic = "fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a"
        wcRelay.clientSynchJsonRpcPublisher.sink { (request) in
            requestExpectation.fulfill()
        }.store(in: &publishers)
        serialiser.deserialised = SerialiserTestData.pairingApproveJSONRPCRequest
        crypto.set(agreementKeys: Crypto.X25519.AgreementKeys(sharedSecret: Data(), publicKey: Data()), topic: topic)
        networkRelayer.onMessage?(topic, testPayload)
        waitForExpectations(timeout: 0.001, handler: nil)
    }
    
    func testRequestCompletesWithSuccessfulResponse() {
        let responseExpectation = expectation(description: "should complete with response")
        
        let topic = "93293932"
        let request = getWCSessionPayloadRequest()
        let sessionPayloadResponse = getWCSessionPayloadResponse()
        serialiser.deserialised = sessionPayloadResponse
        wcRelay.publish(topic: topic, payload: request) { result in
            responseExpectation.fulfill()
            XCTAssertEqual(result, .success(sessionPayloadResponse))
        }
        let response = try! sessionPayloadResponse.json().toHexEncodedString(uppercase: false)
        networkRelayer.error = nil
        networkRelayer.onMessage?(topic, response)
        waitForExpectations(timeout: 0.01, handler: nil)
    }
    
    func testRequestCompletesWithError() {
        
    }
    
    func testRespondCompletesWithoutError() {
        
    }
    
    func getWCSessionPayloadResponse() -> JSONRPCResponse<AnyCodable> {
        let result = AnyCodable("")
        return JSONRPCResponse<AnyCodable>(id: 123456, result: result)
    }
    
    func getWCSessionPayloadRequest() -> ClientSynchJSONRPC {
        let wcRequestId: Int64 = 123456
        let sessionPayloadParams = SessionType.PayloadParams(request: SessionType.PayloadParams.Request(method: "method", params: AnyCodable("params")), chainId: "")
        let params = ClientSynchJSONRPC.Params.sessionPayload(sessionPayloadParams)
        let wcRequest = ClientSynchJSONRPC(id: wcRequestId, method: ClientSynchJSONRPC.Method.sessionPayload, params: params)
        return wcRequest
    }
}

class MockedNetworkRelayer: NetworkRelaying {
    var onConnect: (() -> ())?
    
    var onMessage: ((String, String) -> ())?
    var error: Error?
    func publish(topic: String, payload: String, completion: @escaping ((Error?) -> ())) -> Int64 {
        completion(error)
        return 0
    }
    
    func subscribe(topic: String, completion: @escaping (Error?) -> ()) -> Int64 {
        return 0
    }
    
    func unsubscribe(topic: String, completion: @escaping ((Error?) -> ())) -> Int64? {
        return 0
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
