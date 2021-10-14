
//
//import Foundation
//import Combine
//import XCTest
//@testable import WalletConnect
//
//class RelayTests: XCTestCase {
//    var relay: Relay!
//    var transport: MockedJSONRPCTransport!
//    var serialiser: MockedJSONRPCSerialiser!
//    var crypto: Crypto!
//    private var publishers = [AnyCancellable]()
//
//    override func setUp() {
//        crypto = Crypto(keychain: DictionaryKeychain())
//        serialiser = MockedJSONRPCSerialiser()
//        transport = MockedJSONRPCTransport()
//        relay = Relay(jsonRpcSerialiser: serialiser, transport: transport, crypto: crypto)
//    }
//
//    override func tearDown() {
//        relay = nil
//        transport = nil
//        serialiser = nil
//    }
//    
//    func testNotifyOnClientSynchJsonRpc() {
//        let requestExpectation = expectation(description: "request")
//        let topic = "fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a"
//        relay.clientSynchJsonRpcPublisher.sink { (request) in
//            requestExpectation.fulfill()
//        }.store(in: &publishers)
//        serialiser.deserialised = SerialiserTestData.pairingApproveJSONRPCRequest
//        crypto.set(agreementKeys: Crypto.X25519.AgreementKeys(sharedSecret: Data(), publicKey: Data()), topic: topic)
//        transport.onMessage?(testPayload)
//        waitForExpectations(timeout: 0.001, handler: nil)
//    }
//    
//    func testNotifyOnClientSyncJsonRpcUnencryptedData() {
//        let requestExpectation = expectation(description: "request")
//        relay.clientSynchJsonRpcPublisher.sink { request in
//            XCTAssert(request.clientSynchJsonRpc.method == .pairingApprove)
//            requestExpectation.fulfill()
//        }.store(in: &publishers)
//        transport.onMessage?(SerialiserTestData.unencryptedPairingApproveSubscription)
//        waitForExpectations(timeout: 0.001, handler: nil)
//    }
//    
//    func testPublishRequestAcknowledge() {
//        let acknowledgeExpectation = expectation(description: "acknowledge")
//        let requestId = try! relay.publish(topic: "", payload: "{}") {_ in
//            acknowledgeExpectation.fulfill()
//        }
//        let response = try! JSONRPCResponse<Bool>(id: requestId, result: true).json()
//        transport.onMessage?(response)
//        waitForExpectations(timeout: 0.001, handler: nil)
//    }
//    
//    func testSubscriptionAcknowledgement() {
//        let acknowledgeExpectation = expectation(description: "acknowledge")
//        let requestId = try! relay.subscribe(topic: "") { subscriptionId in
//            acknowledgeExpectation.fulfill()
//        }
//        let subscriptionAcknowledgement = try! JSONRPCResponse<String>(id: requestId, result: "").json()
//        transport.onMessage?(subscriptionAcknowledgement)
//        waitForExpectations(timeout: 0.001, handler: nil)
//    }
//    
//    func testUnsubscribeRequestAcknowledge() {
//        let acknowledgeExpectation = expectation(description: "acknowledge")
//        let requestId = try! relay.unsubscribe(topic: "", id: "") {_ in
//            acknowledgeExpectation.fulfill()
//        }
//        let response = try! JSONRPCResponse<Bool>(id: requestId, result: true).json()
//        transport.onMessage?(response)
//        waitForExpectations(timeout: 0.001, handler: nil)
//    }
//
//    func testSendOnPublish() {
//        _ = try! relay.publish(topic: "", payload: "") {_ in }
//        XCTAssertTrue(transport.sent)
//    }
//    
//    func testSendOnSubscribe() {
//        _ = try! relay.subscribe(topic: "") {_ in }
//        XCTAssertTrue(transport.sent)
//    }
//    
//    func testSendOnUnsubscribe() {
//        _ = try! relay.unsubscribe(topic: "", id: "") {_ in }
//        XCTAssertTrue(transport.sent)
//    }
//}
//
//fileprivate let testPayload =
//"""
//{
//   "id":1630300527198334,
//   "jsonrpc":"2.0",
//   "method":"waku_subscription",
//   "params":{
//      "id":"0847f4e1dd19cf03a43dc7525f39896b630e9da33e4683c8efbc92ea671b5e07",
//      "data":{
//         "topic":"fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a",
//         "message":"7b226964223a313633303330303532383030302c226a736f6e727063223a22322e30222c22726573756c74223a747275657d"
//      }
//   }
//}
//"""
