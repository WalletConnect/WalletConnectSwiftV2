import XCTest
import Combine
@testable import WalletConnect


//
//final class RelayTests: XCTestCase {
//    
//    let url = URL(string: "wss://staging.walletconnect.org")!
//    private var publishers = [AnyCancellable]()
//
//    func makeRelay() -> Relay {
//        let transport = JSONRPCTransport(url: url)
//        return Relay(transport: transport, crypto: Crypto())
//    }
//    
//    func testSubscribe() {
//        let relay = makeRelay()
//        let subscribeExpectation = expectation(description: "subscribe call must succeed")
//        
//        _ = try? relay.subscribe(topic: String.randomTopic()) { result in
//            result.isSuccess ? subscribeExpectation.fulfill() : XCTFail("subscribe result must be a success")
//        }
//        waitForExpectations(timeout: defaultTimeout, handler: nil)
//    }
//    
//    // FIXME: Intermittent failure
////    func testEndToEndPayload() {
////        let relayA = makeRelay()
////        let relayB = makeRelay()
////        
////        let topic = String.randomTopic()
////        let params = PairingType.ApproveParams.stub()
////        let payloadToPublish = ClientSynchJSONRPC(method: .pairingApprove, params: .pairingApprove(params))
////        let expectation = expectation(description: "publish payloads must be sent and received successfuly")
////        expectation.expectedFulfillmentCount = 4
////        
////        relayA.clientSynchJsonRpcPublisher.sink {
////            $0.isPairingApprove ? expectation.fulfill() : XCTFail("unexpected client sync method received")
////        }.store(in: &publishers)
////        relayB.clientSynchJsonRpcPublisher.sink {
////            $0.isPairingApprove ? expectation.fulfill() : XCTFail("unexpected client sync method received")
////        }.store(in: &publishers)
////        
////        let dispatchGroup = DispatchGroup()
////        [relayA, relayB].forEach { relay in
////            dispatchGroup.enter()
////            _ = try! relay.subscribe(topic: topic) { result in
////                if result.isFailure {
////                    XCTFail()
////                }
////                dispatchGroup.leave()
////            }
////        }
////        _ = dispatchGroup.wait(timeout: .now() + defaultTimeout)
////
////        _ = try? relayA.publish(topic: topic, payload: payloadToPublish) { result in
////            result.isSuccess ? expectation.fulfill() : XCTFail("relay A did not receive a success result on publish")
////        }
////        _ = try? relayB.publish(topic: topic, payload: payloadToPublish) { result in
////            result.isSuccess ? expectation.fulfill() : XCTFail("relay B did not receive a success result on publish")
////        }
////        
////        waitForExpectations(timeout: defaultTimeout, handler: nil)
////    }
//}
