import Foundation
import Combine

public class NetworkingInteractor: NetworkInteracting {
    private var tasks = Task.DisposeBag()
    private var publishers = Set<AnyCancellable>()
    private let relayClient: RelayClient
    private let serializer: Serializing
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging

    private let requestPublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, decryptedPayload: Data, publishedAt: Date, derivedTopic: String?, encryptedMessage: String, attestation: String?), Never>()
    private let responsePublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date, derivedTopic: String?), Never>()

    public var requestPublisher: AnyPublisher<(topic: String, request: RPCRequest, decryptedPayload: Data, publishedAt: Date, derivedTopic: String?, encryptedMessage: String, attestation: String?), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private var responsePublisher: AnyPublisher<(topic: String, request: RPCRequest, response: RPCResponse, publishedAt: Date, derivedTopic: String?), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    public var logsPublisher: AnyPublisher<Log, Never> {
        logger.logsPublisher
            .merge(with: serializer.logsPublisher)
            .merge(with: relayClient.logsPublisher)
            .eraseToAnyPublisher()
    }

    public var isSocketConnected: Bool {
        return relayClient.isSocketConnected
    }

    public var networkConnectionStatusPublisher: AnyPublisher<NetworkConnectionStatus, Never>
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
        self.networkConnectionStatusPublisher = relayClient.networkConnectionStatusPublisher
        setupRelaySubscribtion()
    }

    private func setupRelaySubscribtion() {
        relayClient.messagePublisher
            .sink { [unowned self] (topic, message, publishedAt, attestation) in
                manageSubscription(topic, message, publishedAt, attestation)
            }.store(in: &publishers)
    }

    public func setLogging(level: LoggingLevel) {
        logger.setLogging(level: level)
        serializer.setLogging(level: level)
        relayClient.setLogging(level: level)
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

    public func subscribeOnRequest<RequestParams: Codable>(
        protocolMethod: ProtocolMethod,
        requestOfType: RequestParams.Type,
        errorHandler: ErrorHandler?,
        subscription: @escaping (RequestSubscriptionPayload<RequestParams>) async throws -> Void
    ) {
        requestSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: RequestSubscriptionPayload<RequestParams>) in
                Task(priority: .high) {
                    do {
                        try await subscription(payload)
                    } catch {
                        errorHandler?.handle(error: error)
                    }
                }.store(in: &tasks)
            }.store(in: &publishers)
    }

    public func subscribeOnResponse<Request: Codable, Response: Codable>(
        protocolMethod: ProtocolMethod,
        requestOfType: Request.Type,
        responseOfType: Response.Type,
        errorHandler: ErrorHandler?,
        subscription: @escaping (ResponseSubscriptionPayload<Request, Response>) async throws -> Void
    ) {
        responseSubscription(on: protocolMethod)
            .sink { [unowned self] (payload: ResponseSubscriptionPayload<Request, Response>) in
                Task(priority: .high) {
                    do {
                        try await subscription(payload)
                    } catch {
                        errorHandler?.handle(error: error)
                    }
                }.store(in: &tasks)
            }.store(in: &publishers)
    }


    public func requestSubscription<RequestParams: Codable>(on request: ProtocolMethod) -> AnyPublisher<RequestSubscriptionPayload<RequestParams>, Never> {
        return requestPublisher
            .filter { rpcRequest in
                return rpcRequest.request.method == request.method
            }
            .compactMap { [weak self] topic, rpcRequest, decryptedPayload, publishedAt, derivedTopic, encryptedMessage, attestation in
                do {
                    guard let id = rpcRequest.id, let request = try rpcRequest.params?.get(RequestParams.self) else { return nil }
                    return RequestSubscriptionPayload(
                        id: id,
                        topic: topic,
                        request: request,
                        decryptedPayload: decryptedPayload,
                        publishedAt: publishedAt,
                        derivedTopic: derivedTopic,
                        encryptedMessage: encryptedMessage,
                        attestation: attestation
                    )
                } catch {
                    self?.logger.debug("Networking Interactor - \(error)")
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    public func awaitResponse<Request: Codable, Response: Codable>(
        request: RPCRequest,
        topic: String,
        method: ProtocolMethod,
        requestOfType: Request.Type,
        responseOfType: Response.Type,
        envelopeType: Envelope.EnvelopeType
    ) async throws -> Response {
        return try await withCheckedThrowingContinuation { [unowned self] continuation in
            var response, error: AnyCancellable?

            let cancel: () -> Void = {
                response?.cancel()
                error?.cancel()
            }

            response = responseSubscription(on: method)
                .sink { (payload: ResponseSubscriptionPayload<Request, Response>) in
                    cancel()
                    continuation.resume(with: .success(payload.response))
                }

            error = responseErrorSubscription(on: method)
                .sink { (payload: ResponseSubscriptionErrorPayload<Request>) in
                    cancel()
                    continuation.resume(throwing: payload.error)
                }

            Task(priority: .high) {
                do {
                    try await self.request(request, topic: topic, protocolMethod: method, envelopeType: envelopeType)
                } catch {
                    cancel()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

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

    public func responseErrorSubscription<Request: Codable>(on request: ProtocolMethod) -> AnyPublisher<ResponseSubscriptionErrorPayload<Request>, Never> {
        return responsePublisher
            .filter { $0.request.method == request.method }
            .compactMap { topic, rpcRequest, rpcResponse, publishedAt, _ in
                guard let id = rpcResponse.id, let request = try? rpcRequest.params?.get(Request.self), let error = rpcResponse.error else { return nil }
                return ResponseSubscriptionErrorPayload(id: id, topic: topic, request: request, error: error)
            }
            .eraseToAnyPublisher()
    }

    public func request(_ request: RPCRequest, topic: String, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws {
        try rpcHistory.set(request, forTopic: topic, emmitedBy: .local, transportType: .relay)

        do {
            let message = try serializer.serialize(topic: topic, encodable: request, envelopeType: envelopeType)

            try await relayClient.publish(topic: topic,
                payload: message,
                tag: protocolMethod.requestConfig.tag,
                prompt: protocolMethod.requestConfig.prompt,
                ttl: protocolMethod.requestConfig.ttl)
        } catch {
            if let id = request.id {
                rpcHistory.delete(id: id)
            }
            throw error
        }
    }

    public func respond(topic: String, response: RPCResponse, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws {
        try rpcHistory.validate(response)
        let message = try serializer.serialize(topic: topic, encodable: response, envelopeType: envelopeType)
        try await relayClient.publish(topic: topic, payload: message, tag: protocolMethod.responseConfig.tag, prompt: protocolMethod.responseConfig.prompt, ttl: protocolMethod.responseConfig.ttl)
        try rpcHistory.resolve(response)
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

    private func manageSubscription(_ topic: String, _ encodedEnvelope: String, _ publishedAt: Date, _ attestation: String?) {
        if let result = serializer.tryDeserializeRequestOrResponse(topic: topic, codingType: .base64Encoded, envelopeString: encodedEnvelope) {
            switch result {
            case .left(let result):
                handleRequest(topic: topic, request: result.request, decryptedPayload: result.decryptedPayload, publishedAt: publishedAt, derivedTopic: result.derivedTopic, encryptedMessage: encodedEnvelope, attestation: attestation)
            case .right(let result):
                handleResponse(topic: topic, response: result.response, publishedAt: publishedAt, derivedTopic: result.derivedTopic)
            }
        } else {
            logger.debug("Networking Interactor - Received unknown object type from networking relay")
        }
    }
    
    public func handleHistoryRequest(topic: String, request: RPCRequest) {
        requestPublisherSubject.send((topic, request, Data(), Date(), nil, "", nil ))
    }

    private func handleRequest(topic: String, request: RPCRequest, decryptedPayload: Data, publishedAt: Date, derivedTopic: String?, encryptedMessage: String, attestation: String?) {
        do {
            try rpcHistory.set(request, forTopic: topic, emmitedBy: .remote, transportType: .relay)
            requestPublisherSubject.send((topic, request, decryptedPayload, publishedAt, derivedTopic, encryptedMessage, attestation))
        } catch {
            logger.debug(error)
        }
    }

    private func handleResponse(topic: String, response: RPCResponse, publishedAt: Date, derivedTopic: String?) {
        do {
            let record = try rpcHistory.resolve(response)
            responsePublisherSubject.send((topic, record.request, response, publishedAt, derivedTopic))
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
