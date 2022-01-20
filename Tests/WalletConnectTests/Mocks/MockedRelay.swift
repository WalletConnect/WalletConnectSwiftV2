
import Foundation
import Combine
import WalletConnectUtils
@testable import WalletConnect

class MockedWCRelay: WalletConnectRelaying {
    
    var onPairingResponse: ((WCResponse) -> Void)?
    var onResponse: ((WCResponse) -> Void)?
    
    var onPairingApproveResponse: ((String) -> Void)?
    
    var transportConnectionPublisher: AnyPublisher<Void, Never> {
        transportConnectionPublisherSubject.eraseToAnyPublisher()
    }
    private let transportConnectionPublisherSubject = PassthroughSubject<Void, Never>()
    
    private let wcRequestPublisherSubject = PassthroughSubject<WCRequestSubscriptionPayload, Never>()
    var wcRequestPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {
        wcRequestPublisherSubject.eraseToAnyPublisher()
    }
    var didCallSubscribe = false
    var didCallUnsubscribe = false
    var error: Error? = nil
    
    private(set) var requests: [(topic: String, request: WCRequest)] = []

    func request(_ wcMethod: WCMethod, onTopic topic: String, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> ())?) {
        request(topic: topic, payload: wcMethod.asRequest(), completion: completion)
    }
    
    func request(topic: String, payload: WCRequest, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> ())?) {
        requests.append((topic, payload))
    }
    
    func respond(topic: String, response: JsonRpcResponseTypes, completion: @escaping ((Error?) -> ())) {
        completion(error)
    }
    
    func subscribe(topic: String) {
        didCallSubscribe = true
    }
    
    func unsubscribe(topic: String) {
        didCallUnsubscribe = true
    }
    
    func sendSubscriptionPayloadOn(topic: String) {
        let payload = WCRequestSubscriptionPayload(topic: topic,
                                                   wcRequest: SerialiserTestData.pairingApproveJSONRPCRequest)
        wcRequestPublisherSubject.send(payload)
    }
}
