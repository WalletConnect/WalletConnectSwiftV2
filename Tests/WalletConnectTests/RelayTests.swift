
import Foundation
import XCTest
@testable import WalletConnect


class RelayTests: XCTestCase {
    var relay: Relay!
    var transport: MockedJSONRPCTransport!
    var serialiser: MockedJSONRPCSerialiser!
    var crypto: Crypto!

    override func setUp() {
        crypto = Crypto(keychain: DictionaryKeychain())
        serialiser = MockedJSONRPCSerialiser()
        transport = MockedJSONRPCTransport()
        relay = Relay(jsonRpcSerialiser: serialiser, transport: transport, crypto: crypto)
    }

    override func tearDown() {
        relay = nil
        transport = nil
        serialiser = nil
    }
    
    func testNotifySubscriberOnWakuSubscriptionPayload() {
        let topic = "fefc3dc39cacbc562ed58f92b296e2d65a6b07ef08992b93db5b3cb86280635a"
        let subscriptionId = "0847f4e1dd19cf03a43dc7525f39896b630e9da33e4683c8efbc92ea671b5e07"
        serialiser.deserialised = SerialiserTestData.pairingApproveJSONRPCRequest
        let subscriber = MockedRelaySubscriber()
        subscriber.subscriptionIds.append(subscriptionId)
        crypto.set(agreementKeys: Crypto.X25519.AgreementKeys(sharedSecret: Data(), publicKey: Data()), topic: topic)
        relay.addSubscriber(subscriber)
        transport.onMessage?(testPayload)
        XCTAssertNotNil(subscriber.jsonRpcRequest)
    }
    
    func testNotifySubscriberOnRequestAcknowledge() {
        let subscriber = MockedRelaySubscriber()
        subscriber.set(pendingRequestId: 1631033330664162)
        relay.addSubscriber(subscriber)
        transport.onMessage?(testRequestAcknowledgement)
        XCTAssertTrue(subscriber.requestAcknowledged)
    }
    
    func testNotifySubscriberOnSubscriptionAcknowledgement() {
        let subscriber = MockedRelaySubscriber()
        relay.addSubscriber(subscriber)
        subscriber.set(pendingRequestId: 1631033320624908)
        transport.onMessage?(testSubscriptionAcknowledgement)
        XCTAssertTrue(subscriber.subscriptionAcknowledged)
    }

    func testSendOnPublish() {
        let subscriber = MockedRelaySubscriber()
        relay.publish(topic: "", payload: "", subscriber: subscriber)
        XCTAssertTrue(transport.send)
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

fileprivate let testRequestAcknowledgement =
"""
{"id":1631033330664162,"jsonrpc":"2.0","result":true}
"""

fileprivate let testSubscriptionAcknowledgement =
"""
{"id":1631033320624908,"jsonrpc":"2.0","result":"1565a44d5467d02bf6749f894312268d3f6acae78d0adb994dc5ce8d13b6a32e"}
"""
