import Foundation
import Combine
import WalletConnectUtils
import WalletConnectPairing
@testable import WalletConnectSign
@testable import TestingUtils

class NetworkingInteractorMock: NetworkInteracting {

    private(set) var subscriptions: [String] = []
    private(set) var unsubscriptions: [String] = []

    let transportConnectionPublisherSubject = PassthroughSubject<Void, Never>()
    let responsePublisherSubject = PassthroughSubject<WCResponse, Never>()
    let wcRequestPublisherSubject = PassthroughSubject<WCRequestSubscriptionPayload, Never>()

    var transportConnectionPublisher: AnyPublisher<Void, Never> {
        transportConnectionPublisherSubject.eraseToAnyPublisher()
    }
    var wcRequestPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {
        wcRequestPublisherSubject.eraseToAnyPublisher()
    }
    var responsePublisher: AnyPublisher<WCResponse, Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    var didCallSubscribe = false
    var didRespondOnTopic: String?
    var didCallUnsubscribe = false
    var didRespondSuccess = false
    var didRespondError = false
    var lastErrorCode = -1
    var error: Error?

    private(set) var requestCallCount = 0
    var didCallRequest: Bool { requestCallCount > 0 }

    private(set) var requests: [(topic: String, request: WCRequest)] = []

    func request(topic: String, payload: WCRequest) async throws {
        requestCallCount += 1
        requests.append((topic, payload))
    }

    func requestNetworkAck(_ wcMethod: WCMethod, onTopic topic: String, completion: @escaping ((Error?) -> Void)) {
        requestCallCount += 1
        requests.append((topic, wcMethod.asRequest()))
        completion(nil)
    }

    func requestPeerResponse(_ wcMethod: WCMethod, onTopic topic: String, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> Void)?) {
        requestCallCount += 1
        requests.append((topic, wcMethod.asRequest()))
    }

    func respond(topic: String, response: JsonRpcResult, completion: @escaping ((Error?) -> Void)) {
        didRespondOnTopic = topic
        completion(error)
    }

    func respond(topic: String, response: JsonRpcResult, tag: Int) async throws {
        didRespondOnTopic = topic
    }

    func respondSuccess(payload: WCRequestSubscriptionPayload) async throws {
        respondSuccess(for: payload)
    }

    func respondError(payload: WCRequestSubscriptionPayload, reason: ReasonCode) async throws {
        lastErrorCode = reason.code
        didRespondError = true
    }

    func respondSuccess(for payload: WCRequestSubscriptionPayload) {
        didRespondSuccess = true
    }

    func subscribe(topic: String) {
        didCallSubscribe = true
        subscriptions.append(topic)
    }

    func unsubscribe(topic: String) {
        unsubscriptions.append(topic)
        didCallUnsubscribe = true
    }

    func sendSubscriptionPayloadOn(topic: String) {
        let payload = WCRequestSubscriptionPayload(topic: topic, wcRequest: pingRequest)
        wcRequestPublisherSubject.send(payload)
    }

    func didSubscribe(to topic: String) -> Bool {
        subscriptions.contains { $0 == topic }
    }

    func didUnsubscribe(to topic: String) -> Bool {
        unsubscriptions.contains { $0 == topic }
    }
}

private let pingRequest = WCRequest(id: 1, jsonrpc: "2.0", method: .pairingPing, params: WCRequest.Params.pairingPing(PairingType.PingParams()))
