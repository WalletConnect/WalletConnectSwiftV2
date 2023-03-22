import Foundation
import Combine
import JSONRPC
import WalletConnectRelay
import WalletConnectKMS
import WalletConnectNetworking

public class NetworkingInteractorMock: NetworkInteracting {

    private(set) var subscriptions: [String] = []
    private(set) var unsubscriptions: [String] = []

    private(set) var requests: [(topic: String, request: RPCRequest)] = []

    private(set) var didRespondSuccess = false
    private(set) var didRespondError = false
    private(set) var didCallSubscribe = false
    private(set) var didCallUnsubscribe = false
    private(set) var didRespondOnTopic: String?
    private(set) var lastErrorCode = -1

    private(set) var requestCallCount = 0
    var didCallRequest: Bool { requestCallCount > 0 }

    var onSubscribeCalled: (() -> Void)?
    var onRespondError: ((Int) -> Void)?

    public let socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()
    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    public let requestPublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, publishedAt: Date), Never>()
    public let responsePublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date), Never>()

    public var requestPublisher: AnyPublisher<(topic: String, request: RPCRequest, publishedAt: Date), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private var responsePublisher: AnyPublisher<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    // TODO: Avoid copy paste from NetworkInteractor
    public func requestSubscription<Request: Codable>(on request: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<Request>, Never> {
        return requestPublisher
            .filter { rpcRequest in
                return rpcRequest.request.method == request.method
            }
            .compactMap { topic, rpcRequest, publishedAt in
                guard let id = rpcRequest.id, let request = try? rpcRequest.params?.get(Request.self) else { return nil }
                return RequestSubscriptionPayload(id: id, topic: topic, request: request, publishedAt: publishedAt)
            }
            .eraseToAnyPublisher()
    }

    // TODO: Avoid copy paste from NetworkInteractor
    public func responseSubscription<Request: Codable, Response: Codable>(on request: ProtocolMethod) -> AnyPublisher<ResponseSubscriptionPayload<Request, Response>, Never> {
        return responsePublisher
            .filter { rpcRequest in
                return rpcRequest.request.method == request.method
            }
            .compactMap { topic, rpcRequest, rpcResponse, publishedAt  in
                guard
                    let id = rpcRequest.id,
                    let request = try? rpcRequest.params?.get(Request.self),
                    let response = try? rpcResponse.result?.get(Response.self) else { return nil }
                return ResponseSubscriptionPayload(id: id, topic: topic, request: request, response: response, publishedAt: publishedAt)
            }
            .eraseToAnyPublisher()
    }

    // TODO: Avoid copy paste from NetworkInteractor
    public func responseErrorSubscription<Request: Codable>(on request: ProtocolMethod) -> AnyPublisher<ResponseSubscriptionErrorPayload<Request>, Never> {
        return responsePublisher
            .filter { $0.request.method == request.method }
            .compactMap { (topic, rpcRequest, rpcResponse, publishedAt) in
                guard let id = rpcResponse.id, let request = try? rpcRequest.params?.get(Request.self), let error = rpcResponse.error else { return nil }
                return ResponseSubscriptionErrorPayload(id: id, topic: topic, request: request, error: error)
            }
            .eraseToAnyPublisher()
    }

    public func subscribe(topic: String) async throws {
        defer { onSubscribeCalled?() }
        subscriptions.append(topic)
        didCallSubscribe = true
    }

    func didSubscribe(to topic: String) -> Bool {
        subscriptions.contains { $0 == topic }
    }

    func didUnsubscribe(to topic: String) -> Bool {
        unsubscriptions.contains { $0 == topic }
    }

    public func unsubscribe(topic: String) {
        unsubscriptions.append(topic)
        didCallUnsubscribe = true
    }

    public func batchUnsubscribe(topics: [String]) async throws {
        for topic in topics {
            unsubscribe(topic: topic)
        }
    }

    public func batchSubscribe(topics: [String]) async throws {
        for topic in topics {
            try await subscribe(topic: topic)
        }
    }

    public func request(_ request: RPCRequest, topic: String, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws {
        requestCallCount += 1
        requests.append((topic, request))
    }

    public func respond(topic: String, response: RPCResponse, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws {
        didRespondOnTopic = topic
    }

    public func respondSuccess(topic: String, requestId: RPCID, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws {
        didRespondSuccess = true
    }

    public func respondError(topic: String, requestId: RPCID, protocolMethod: ProtocolMethod, reason: Reason, envelopeType: Envelope.EnvelopeType) async throws {
        lastErrorCode = reason.code
        didRespondError = true
        onRespondError?(reason.code)
    }

    public func requestNetworkAck(_ request: RPCRequest, topic: String, protocolMethod: ProtocolMethod) async throws {
        requestCallCount += 1
        requests.append((topic, request))
    }

    public func getClientId() throws -> String {
        return ""
    }
}
