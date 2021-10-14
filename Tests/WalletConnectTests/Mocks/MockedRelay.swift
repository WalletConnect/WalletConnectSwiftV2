//
//import Foundation
//import Combine
//@testable import WalletConnect
//
//class MockedRelay: Relaying {
//    var transportConnectionPublisher: AnyPublisher<Void, Never> {
//        transportConnectionPublisherSubject.eraseToAnyPublisher()
//    }
//    private let transportConnectionPublisherSubject = PassthroughSubject<Void, Never>()
//    
//    var wcResponsePublisher: AnyPublisher<JSONRPCResponse<String>, Never> {
//        wcResponsePublisherSubject.eraseToAnyPublisher()
//    }
//    private let wcResponsePublisherSubject = PassthroughSubject<JSONRPCResponse<String>, Never>()
//    
//    private let clientSynchJsonRpcPublisherSubject = PassthroughSubject<WCRequestSubscriptionPayload, Never>()
//    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {
//        clientSynchJsonRpcPublisherSubject.eraseToAnyPublisher()
//    }
//    var subscribeCompletionId: String = ""
//    var didCallSubscribe = false
//    var didCallUnsubscribe = false
//    var didCallPublish = false
//    func publish(topic: String, payload: Encodable, completion: @escaping ((Result<Void, Error>) -> ())) throws -> Int64 {
//        didCallPublish = true
//        return 0
//    }
//    
//    func subscribe(topic: String, completion: @escaping ((Result<String, Error>) -> ())) throws -> Int64 {
//        didCallSubscribe = true
//        completion(.success(subscribeCompletionId))
//        return 0
//    }
//    
//    func unsubscribe(topic: String, id: String, completion: @escaping ((Result<Void, Error>) -> ())) throws -> Int64 {
//        didCallUnsubscribe = true
//        completion(.success(()))
//        return 0
//    }
//    
//    func sendSubscriptionPayloadOn(topic: String, subscriptionId: String) {
//        let payload = WCRequestSubscriptionPayload(topic: topic,
//                                            subscriptionId: subscriptionId,
//                                            clientSynchJsonRpc: SerialiserTestData.pairingApproveJSONRPCRequest)
//        clientSynchJsonRpcPublisherSubject.send(payload)
//    }
//}
