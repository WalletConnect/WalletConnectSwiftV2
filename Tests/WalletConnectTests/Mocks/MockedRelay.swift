
import Foundation
import Combine
import WalletConnectUtils
@testable import WalletConnect
@testable import TestingUtils

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
    var didRespondSuccess = false
    var lastErrorCode = -1
    var error: Error? = nil
    
    private(set) var requestCallCount = 0
    var didCallRequest: Bool { requestCallCount > 0 }
    
    private(set) var requests: [(topic: String, request: WCRequest)] = []
    
    func request(_ wcMethod: WCMethod, onTopic topic: String, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> ())?) {
        request(topic: topic, payload: wcMethod.asRequest(), completion: completion)
    }
    
    func request(topic: String, payload: WCRequest, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> ())?) {
        requestCallCount += 1
        requests.append((topic, payload))
    }
    
    func respond(topic: String, response: JsonRpcResult, completion: @escaping ((Error?) -> ())) {
        completion(error)
    }
    
    func respondSuccess(for payload: WCRequestSubscriptionPayload) {
        didRespondSuccess = true
    }
    
    func respondError(for payload: WCRequestSubscriptionPayload, reason: ReasonCode) {
        lastErrorCode = reason.code
    }
    
    func subscribe(topic: String) {
        didCallSubscribe = true
    }
    
    func unsubscribe(topic: String) {
        didCallUnsubscribe = true
    }
    
    func sendSubscriptionPayloadOn(topic: String) {
        let payload = WCRequestSubscriptionPayload(topic: topic, wcRequest: pingRequest)
        wcRequestPublisherSubject.send(payload)
    }
}

fileprivate let pingRequest = WCRequest(id: 1, jsonrpc: "2.0", method: .pairingPing, params: WCRequest.Params.pairingPing(PairingType.PingParams()))
