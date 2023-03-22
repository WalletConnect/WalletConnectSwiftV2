import Foundation
import Combine


public class NetworkingInteractor: NetworkInteracting {
    private var publishers = Set<AnyCancellable>()
    private let relayClient: RelayClient
    private let serializer: Serializing
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging

    private let requestPublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, publishedAt: Date), Never>()
    private let responsePublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date), Never>()

    public var requestPublisher: AnyPublisher<(topic: String, request: RPCRequest, publishedAt: Date), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private var responsePublisher: AnyPublisher<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never>

    public init(
        relayClient: RelayClient,
        serializer: Serializing,
        logger: ConsoleLogging,
        rpcHistory: RPCHistory
    ) {
        self.relayClient = relayClient
        self.serializer = serializer
        self.rpcHistory = rpcHistory
        self.logger = logger
        self.socketConnectionStatusPublisher = relayClient.socketConnectionStatusPublisher
        setupRelaySubscribtion()
    }

    private func setupRelaySubscribtion() {
        relayClient.messagePublisher
            .sink { [unowned self] (topic, message, publishedAt) in
                manageSubscription(topic, message, publishedAt)
            }.store(in: &publishers)
    }

    public func subscribe(topic: String) async throws {
        try await relayClient.subscribe(topic: topic)
    }

    public func unsubscribe(topic: String) {
        relayClient.unsubscribe(topic: topic) { [unowned self] error in
            if let error = error {
                logger.error(error)
            } else {
                rpcHistory.deleteAll(forTopic: topic)
            }
        }
    }

    public func batchSubscribe(topics: [String]) async throws {
        try await relayClient.batchSubscribe(topics: topics)
    }

    public func batchUnsubscribe(topics: [String]) async throws {
        try await relayClient.batchUnsubscribe(topics: topics)
        rpcHistory.deleteAll(forTopics: topics)
    }

    public func requestSubscription<RequestParams: Codable>(on request: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never> {
        return requestPublisher
            .filter { rpcRequest in
                return rpcRequest.request.method == request.method
            }
            .compactMap { (topic, rpcRequest, publishedAt) in
                guard let id = rpcRequest.id, let request = try? rpcRequest.params?.get(RequestParams.self) else { return nil }
                return RequestSubscriptionPayload(id: id, topic: topic, request: request, publishedAt: publishedAt)
            }
            .eraseToAnyPublisher()
    }

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

    public func responseErrorSubscription<Request: Codable>(on request: ProtocolMethod) -> AnyPublisher<ResponseSubscriptionErrorPayload<Request>, Never> {
        return responsePublisher
            .filter { $0.request.method == request.method }
            .compactMap { topic, rpcRequest, rpcResponse, publishedAt in
                guard let id = rpcResponse.id, let request = try? rpcRequest.params?.get(Request.self), let error = rpcResponse.error else { return nil }
                return ResponseSubscriptionErrorPayload(id: id, topic: topic, request: request, error: error)
            }
            .eraseToAnyPublisher()
    }

    public func request(_ request: RPCRequest, topic: String, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws {
        try rpcHistory.set(request, forTopic: topic, emmitedBy: .local)
        let message = try serializer.serialize(topic: topic, encodable: request, envelopeType: envelopeType)
        try await relayClient.publish(topic: topic, payload: message, tag: protocolMethod.requestConfig.tag, prompt: protocolMethod.requestConfig.prompt, ttl: protocolMethod.requestConfig.ttl)
    }

    public func respond(topic: String, response: RPCResponse, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws {
        try rpcHistory.resolve(response)
        let message = try! serializer.serialize(topic: topic, encodable: response, envelopeType: envelopeType)
        try await relayClient.publish(topic: topic, payload: message, tag: protocolMethod.responseConfig.tag, prompt: protocolMethod.responseConfig.prompt, ttl: protocolMethod.responseConfig.ttl)
    }

    public func respondSuccess(topic: String, requestId: RPCID, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws {
        let response = RPCResponse(id: requestId, result: true)
        try await respond(topic: topic, response: response, protocolMethod: protocolMethod, envelopeType: envelopeType)
    }

    public func getClientId() throws -> String {
        try relayClient.getClientId()
    }

    public func respondError(topic: String, requestId: RPCID, protocolMethod: ProtocolMethod, reason: Reason, envelopeType: Envelope.EnvelopeType) async throws {
        let error = JSONRPCError(code: reason.code, message: reason.message)
        let response = RPCResponse(id: requestId, error: error)
        try await respond(topic: topic, response: response, protocolMethod: protocolMethod, envelopeType: envelopeType)
    }

    private func manageSubscription(_ topic: String, _ encodedEnvelope: String, _ publishedAt: Date) {
        if let deserializedJsonRpcRequest: RPCRequest = serializer.tryDeserialize(topic: topic, encodedEnvelope: encodedEnvelope) {
            handleRequest(topic: topic, request: deserializedJsonRpcRequest, publishedAt: publishedAt)
        } else if let response: RPCResponse = serializer.tryDeserialize(topic: topic, encodedEnvelope: encodedEnvelope) {
            handleResponse(response: response, publishedAt: publishedAt)
        } else {
            logger.debug("Networking Interactor - Received unknown object type from networking relay")
        }
    }

    private func handleRequest(topic: String, request: RPCRequest, publishedAt: Date) {
        do {
            try rpcHistory.set(request, forTopic: topic, emmitedBy: .remote)
            requestPublisherSubject.send((topic, request, publishedAt))
        } catch {
            logger.debug(error)
        }
    }

    private func handleResponse(response: RPCResponse, publishedAt: Date) {
        do {
            try rpcHistory.resolve(response)
            let record = rpcHistory.get(recordId: response.id!)!
            responsePublisherSubject.send((record.topic, record.request, response, publishedAt))
        } catch {
            logger.debug("Handle json rpc response error: \(error)")
        }
    }
}

extension NetworkingInteractor: NetworkingClient {
    public func connect() throws {
        try relayClient.connect()
    }

    public func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        try relayClient.disconnect(closeCode: closeCode)
    }
}
