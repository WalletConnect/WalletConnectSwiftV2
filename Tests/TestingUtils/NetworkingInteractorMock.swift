import Foundation
import Combine
import JSONRPC
import WalletConnectRelay
import WalletConnectKMS
import WalletConnectNetworking

public class NetworkingInteractorMock: NetworkInteracting {
    public var isSocketConnected: Bool = true


    private var publishers = Set<AnyCancellable>()

    private(set) var subscriptions: [String] = []
    private(set) var unsubscriptions: [String] = []

    private(set) var requests: [(topic: String, request: RPCRequest)] = []

    private(set) var didRespondSuccess = false
    private(set) var didRespondError = false
    private(set) var didCallSubscribe = false
    private(set) var didCallUnsubscribe = false
    private(set) var didCallHandleHistoryRequest = false
    private(set) var didRespondOnTopic: String?
    private(set) var lastErrorCode = -1

    private(set) var requestCallCount = 0
    var didCallRequest: Bool { requestCallCount > 0 }

    var onSubscribeCalled: (() -> Void)?
    var onRespondError: ((Int) -> Void)?

    public let socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()
    public let networkConnectionStatusPublisherSubject = CurrentValueSubject<NetworkConnectionStatus, Never>(.connected)
    
    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }
    public var networkConnectionStatusPublisher: AnyPublisher<WalletConnectRelay.NetworkConnectionStatus, Never> {
        networkConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    public let requestPublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, decryptedPayload: Data, publishedAt: Date, derivedTopic: String?, encryptedMessage: String, attestation: String?), Never>()
    public let responsePublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date, derivedTopic: String?), Never>()

    public var requestPublisher: AnyPublisher<(topic: String, request: JSONRPC.RPCRequest, decryptedPayload: Data, publishedAt: Date, derivedTopic: String?, encryptedMessage: String, attestation: String?), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private var responsePublisher: AnyPublisher<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date, derivedTopic: String?), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    private let errorPublisherSubject = PassthroughSubject<Error, Never>()

    public var errorPublisher: AnyPublisher<Error, Never> {
        return errorPublisherSubject.eraseToAnyPublisher()
    }

    // TODO: Avoid copy paste from NetworkInteractor
    public func requestSubscription<Request: Codable>(on request: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<Request>, Never> {
        return requestPublisher
            .filter { rpcRequest in
                return rpcRequest.request.method == request.method
            }
            .compactMap { topic, rpcRequest, decryptedPayload, publishedAt, derivedTopic, encryptedMessage, attestation in
                guard let id = rpcRequest.id, let request = try? rpcRequest.params?.get(Request.self) else { return nil }
                return RequestSubscriptionPayload(id: id, topic: topic, request: request, decryptedPayload: decryptedPayload, publishedAt: publishedAt, derivedTopic: derivedTopic, encryptedMessage: encryptedMessage, attestation: attestation)
            }
            .eraseToAnyPublisher()
    }

    // TODO: Avoid copy paste from NetworkInteractor
    public func responseSubscription<Request: Codable, Response: Codable>(on request: ProtocolMethod) -> AnyPublisher<ResponseSubscriptionPayload<Request, Response>, Never> {
        return responsePublisher
            .filter { rpcRequest in
                return rpcRequest.request.method == request.method
            }
            .compactMap { topic, rpcRequest, rpcResponse, publishedAt, derivedTopic  in
                guard
                    let id = rpcRequest.id,
                    let request = try? rpcRequest.params?.get(Request.self),
                    let response = try? rpcResponse.result?.get(Response.self) else { return nil }
                return ResponseSubscriptionPayload(id: id, topic: topic, request: request, response: response, publishedAt: publishedAt, derivedTopic: derivedTopic)
            }
            .eraseToAnyPublisher()
    }

    // TODO: Avoid copy paste from NetworkInteractor
    public func responseErrorSubscription<Request: Codable>(on request: ProtocolMethod) -> AnyPublisher<ResponseSubscriptionErrorPayload<Request>, Never> {
        return responsePublisher
            .filter { $0.request.method == request.method }
            .compactMap { (topic, rpcRequest, rpcResponse, publishedAt, _) in
                guard let id = rpcResponse.id, let request = try? rpcRequest.params?.get(Request.self), let error = rpcResponse.error else { return nil }
                return ResponseSubscriptionErrorPayload(id: id, topic: topic, request: request, error: error)
            }
            .eraseToAnyPublisher()
    }

    // TODO: Avoid copy paste from NetworkInteractor
    public func subscribeOnRequest<RequestParams: Codable>(
        protocolMethod: ProtocolMethod,
        requestOfType: RequestParams.Type,
        errorHandler: ErrorHandler?,
        subscription: @escaping (RequestSubscriptionPayload<RequestParams>) async throws -> Void
    ) {
        requestSubscription(on: protocolMethod)
            .sink { (payload: RequestSubscriptionPayload<RequestParams>) in
                Task(priority: .high) {
                    do {
                        try await subscription(payload)
                    } catch {
                        errorHandler?.handle(error: error)
                    }
                }
            }.store(in: &publishers)
    }

    // TODO: Avoid copy paste from NetworkInteractor
    public func subscribeOnResponse<Request: Codable, Response: Codable>(
        protocolMethod: ProtocolMethod,
        requestOfType: Request.Type,
        responseOfType: Response.Type,
        errorHandler: ErrorHandler?,
        subscription: @escaping (ResponseSubscriptionPayload<Request, Response>) async throws -> Void
    ) {
        responseSubscription(on: protocolMethod)
            .sink { (payload: ResponseSubscriptionPayload<Request, Response>) in
                Task(priority: .high) {
                    do {
                        try await subscription(payload)
                    } catch {
                        errorHandler?.handle(error: error)
                    }
                }
            }.store(in: &publishers)
    }

    public func awaitResponse<Request: Codable, Response: Codable>(
        request: RPCRequest,
        topic: String,
        method: ProtocolMethod,
        requestOfType: Request.Type,
        responseOfType: Response.Type,
        envelopeType: Envelope.EnvelopeType
    ) async throws -> Response {

        try await self.request(request, topic: topic, protocolMethod: method, envelopeType: envelopeType)

        return try await withCheckedThrowingContinuation { [unowned self] continuation in
            var response, error: AnyCancellable?

            response = responseSubscription(on: method)
                .sink { (payload: ResponseSubscriptionPayload<Request, Response>) in
                    response?.cancel()
                    error?.cancel()
                    continuation.resume(with: .success(payload.response))
                }

            error = responseErrorSubscription(on: method)
                .sink { (payload: ResponseSubscriptionErrorPayload<Request>) in
                    response?.cancel()
                    error?.cancel()
                    continuation.resume(throwing: payload.error)
                }
        }
    }

    public func subscribe(topic: String) async throws {
        defer { onSubscribeCalled?() }
        subscriptions.append(topic)
        didCallSubscribe = true
    }
    
    public func handleHistoryRequest(topic: String, request: JSONRPC.RPCRequest) {
        didCallHandleHistoryRequest = true
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
