
import Foundation
import Combine
@testable import WalletConnect

class MockedWCRelay: WalletConnectRelaying {
    
    var transportConnectionPublisher: AnyPublisher<Void, Never> {
        transportConnectionPublisherSubject.eraseToAnyPublisher()
    }
    private let transportConnectionPublisherSubject = PassthroughSubject<Void, Never>()
    
    private let clientSynchJsonRpcPublisherSubject = PassthroughSubject<WCRequestSubscriptionPayload, Never>()
    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {
        clientSynchJsonRpcPublisherSubject.eraseToAnyPublisher()
    }
    var didCallSubscribe = false
    var didCallUnsubscribe = false
    var didCallPublish = false
    var error: Error? = nil

    func request(topic: String, payload: ClientSynchJSONRPC, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> ())) {
        didCallPublish = true
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
                                            clientSynchJsonRpc: SerialiserTestData.pairingApproveJSONRPCRequest)
        clientSynchJsonRpcPublisherSubject.send(payload)
    }
}
