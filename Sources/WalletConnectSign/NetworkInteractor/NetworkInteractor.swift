//import Foundation
//import Combine
//import WalletConnectUtils
//import WalletConnectKMS
//
//protocol NetworkInteracting: AnyObject {
//    var transportConnectionPublisher: AnyPublisher<Void, Never> {get}
//    var wcRequestPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {get}
//    var responsePublisher: AnyPublisher<WCResponse, Never> {get}
//    /// Completes when request sent from a networking client
//    func request(_ wcMethod: WCMethod, onTopic topic: String) async throws
//    /// Completes with an acknowledgement from the relay network
//    func requestNetworkAck(_ wcMethod: WCMethod, onTopic topic: String, completion: @escaping ((Error?) -> Void))
//    /// Completes with a peer response
//    func requestPeerResponse(_ wcMethod: WCMethod, onTopic topic: String, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> Void)?)
//    func respond(topic: String, response: JsonRpcResult, tag: Int) async throws
//    func respondSuccess(payload: WCRequestSubscriptionPayload) async throws
//    func respondSuccess(for payload: WCRequestSubscriptionPayload)
//    func respondError(payload: WCRequestSubscriptionPayload, reason: ReasonCode) async throws
//    func subscribe(topic: String) async throws
//    func unsubscribe(topic: String)
//}
//
//extension NetworkInteracting {
//    func request(_ wcMethod: WCMethod, onTopic topic: String) {
//        requestPeerResponse(wcMethod, onTopic: topic, completion: nil)
//    }
//}
//
//class NetworkInteractor: NetworkInteracting {
//
//    private var publishers = Set<AnyCancellable>()
//
//    private var relayClient: NetworkRelaying
//    private let serializer: Serializing
//    private let jsonRpcHistory: JsonRpcHistoryRecording
//
//    private let transportConnectionPublisherSubject = PassthroughSubject<Void, Never>()
//    private let responsePublisherSubject = PassthroughSubject<WCResponse, Never>()
//    private let wcRequestPublisherSubject = PassthroughSubject<WCRequestSubscriptionPayload, Never>()
//
//    var transportConnectionPublisher: AnyPublisher<Void, Never> {
//        transportConnectionPublisherSubject.eraseToAnyPublisher()
//    }
//    var wcRequestPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {
//        wcRequestPublisherSubject.eraseToAnyPublisher()
//    }
//    var responsePublisher: AnyPublisher<WCResponse, Never> {
//        responsePublisherSubject.eraseToAnyPublisher()
//    }
//
//    let logger: ConsoleLogging
//
//    init(relayClient: NetworkRelaying,
//         serializer: Serializing,
//         logger: ConsoleLogging,
//         jsonRpcHistory: JsonRpcHistoryRecording) {
//        self.relayClient = relayClient
//        self.serializer = serializer
//        self.logger = logger
//        self.jsonRpcHistory = jsonRpcHistory
//        setUpPublishers()
//    }
//
//    func request(_ wcMethod: WCMethod, onTopic topic: String) async throws {
//        try await request(topic: topic, payload: wcMethod.asRequest())
//    }
//
//    /// Completes when networking client sends a request
//    func request(topic: String, payload: WCRequest) async throws {
//        try jsonRpcHistory.set(topic: topic, request: payload, chainId: getChainId(payload))
//        let message = try serializer.serialize(topic: topic, encodable: payload)
//        let prompt = shouldPrompt(payload.method)
//        try await relayClient.publish(topic: topic, payload: message, tag: payload.tag, prompt: prompt)
//    }
//
//    func requestPeerResponse(_ wcMethod: WCMethod, onTopic topic: String, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> Void)?) {
//        let payload = wcMethod.asRequest()
//        do {
//            try jsonRpcHistory.set(topic: topic, request: payload, chainId: getChainId(payload))
//            let message = try serializer.serialize(topic: topic, encodable: payload)
//            let prompt = shouldPrompt(payload.method)
//            relayClient.publish(topic: topic, payload: message, tag: payload.tag, prompt: prompt) { [weak self] error in
//                guard let self = self else {return}
//                if let error = error {
//                    self.logger.error(error)
//                } else {
//                    var cancellable: AnyCancellable!
//                    cancellable = self.responsePublisher
//                        .filter {$0.result.id == payload.id}
//                        .sink { (response) in
//                            cancellable.cancel()
//                            self.logger.debug("WC Relay - received response on topic: \(topic)")
//                            switch response.result {
//                            case .response(let response):
//                                completion?(.success(response))
//                            case .error(let error):
//                                self.logger.debug("Request error: \(error)")
//                                completion?(.failure(error))
//                            }
//                        }
//                }
//            }
//        } catch WalletConnectError.internal(.jsonRpcDuplicateDetected) {
//            logger.info("Info: Json Rpc Duplicate Detected")
//        } catch {
//            logger.error(error)
//        }
//    }
//
//    /// Completes with an acknowledgement from the relay network.
//    /// completes with error if networking client was not able to send a message
//    func requestNetworkAck(_ wcMethod: WCMethod, onTopic topic: String, completion: @escaping ((Error?) -> Void)) {
//        do {
//            let payload = wcMethod.asRequest()
//            try jsonRpcHistory.set(topic: topic, request: payload, chainId: getChainId(payload))
//            let message = try serializer.serialize(topic: topic, encodable: payload)
//            let prompt = shouldPrompt(payload.method)
//            relayClient.publish(topic: topic, payload: message, tag: payload.tag, prompt: prompt) { error in
//                completion(error)
//            }
//        } catch WalletConnectError.internal(.jsonRpcDuplicateDetected) {
//            logger.info("Info: Json Rpc Duplicate Detected")
//        } catch {
//            logger.error(error)
//        }
//    }
//
//    func respond(topic: String, response: JsonRpcResult, tag: Int) async throws {
//        _ = try jsonRpcHistory.resolve(response: response)
//
//        let message = try serializer.serialize(topic: topic, encodable: response.value)
//        logger.debug("Responding....topic: \(topic)")
//
//        do {
//            try await relayClient.publish(topic: topic, payload: message, tag: tag, prompt: false)
//        } catch WalletConnectError.internal(.jsonRpcDuplicateDetected) {
//            logger.info("Info: Json Rpc Duplicate Detected")
//        }
//    }
//
//    func respondSuccess(payload: WCRequestSubscriptionPayload) async throws {
//        let response = JSONRPCResponse<AnyCodable>(id: payload.wcRequest.id, result: AnyCodable(true))
//        try await respond(topic: payload.topic, response: JsonRpcResult.response(response), tag: payload.wcRequest.responseTag)
//    }
//
//    func respondError(payload: WCRequestSubscriptionPayload, reason: ReasonCode) async throws {
//        let response = JSONRPCErrorResponse(id: payload.wcRequest.id, error: JSONRPCErrorResponse.Error(code: reason.code, message: reason.message))
//        try await respond(topic: payload.topic, response: JsonRpcResult.error(response), tag: payload.wcRequest.responseTag)
//    }
//
//    // TODO: Move to async
//    func respondSuccess(for payload: WCRequestSubscriptionPayload) {
//        Task(priority: .background) {
//            do {
//                try await respondSuccess(payload: payload)
//            } catch {
//                self.logger.error("Respond Success failed with: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    func subscribe(topic: String) async throws {
//        try await relayClient.subscribe(topic: topic)
//    }
//
//    func unsubscribe(topic: String) {
//        relayClient.unsubscribe(topic: topic) { [weak self] error in
//            if let error = error {
//                self?.logger.error(error)
//            } else {
//                self?.jsonRpcHistory.delete(topic: topic)
//            }
//        }
//    }
//
//    // MARK: - Private
//
//    private func setUpPublishers() {
//        relayClient.socketConnectionStatusPublisher.sink { [weak self] status in
//            if status == .connected {
//                self?.transportConnectionPublisherSubject.send()
//            }
//        }.store(in: &publishers)
//
//        relayClient.messagePublisher.sink { [weak self] (topic, message) in
//            self?.manageSubscription(topic, message)
//        }
//        .store(in: &publishers)
//    }
//
//    private func manageSubscription(_ topic: String, _ encodedEnvelope: String) {
//        if let deserializedJsonRpcRequest: WCRequest = serializer.tryDeserialize(topic: topic, encodedEnvelope: encodedEnvelope) {
//            handleWCRequest(topic: topic, request: deserializedJsonRpcRequest)
//        } else if let deserializedJsonRpcResponse: JSONRPCResponse<AnyCodable> = serializer.tryDeserialize(topic: topic, encodedEnvelope: encodedEnvelope) {
//            handleJsonRpcResponse(response: deserializedJsonRpcResponse)
//        } else if let deserializedJsonRpcError: JSONRPCErrorResponse = serializer.tryDeserialize(topic: topic, encodedEnvelope: encodedEnvelope) {
//            handleJsonRpcErrorResponse(response: deserializedJsonRpcError)
//        } else {
//            logger.warn("Warning: Networking Interactor - Received unknown object type from networking relay")
//        }
//    }
//
//    private func handleWCRequest(topic: String, request: WCRequest) {
//        do {
//            try jsonRpcHistory.set(topic: topic, request: request, chainId: getChainId(request))
//            let payload = WCRequestSubscriptionPayload(topic: topic, wcRequest: request)
//            wcRequestPublisherSubject.send(payload)
//        } catch WalletConnectError.internal(.jsonRpcDuplicateDetected) {
//            logger.info("Info: Json Rpc Duplicate Detected")
//        } catch {
//            logger.error(error)
//        }
//    }
//
//    private func handleJsonRpcResponse(response: JSONRPCResponse<AnyCodable>) {
//        do {
//            let record = try jsonRpcHistory.resolve(response: JsonRpcResult.response(response))
//            let wcResponse = WCResponse(
//                topic: record.topic,
//                chainId: record.chainId,
//                requestMethod: record.request.method,
//                requestParams: record.request.params,
//                result: JsonRpcResult.response(response))
//            responsePublisherSubject.send(wcResponse)
//        } catch {
//            logger.info("Info: \(error.localizedDescription)")
//        }
//    }
//
//    private func handleJsonRpcErrorResponse(response: JSONRPCErrorResponse) {
//        do {
//            let record = try jsonRpcHistory.resolve(response: JsonRpcResult.error(response))
//            let wcResponse = WCResponse(
//                topic: record.topic,
//                chainId: record.chainId,
//                requestMethod: record.request.method,
//                requestParams: record.request.params,
//                result: JsonRpcResult.error(response))
//            responsePublisherSubject.send(wcResponse)
//        } catch {
//            logger.info("Info: \(error.localizedDescription)")
//        }
//    }
//
//    private func shouldPrompt(_ method: WCRequest.Method) -> Bool {
//        switch method {
//        case .sessionRequest:
//            return true
//        default:
//            return false
//        }
//    }
//
//    func getChainId(_ request: WCRequest) -> String? {
//        guard case let .sessionRequest(payload) = request.params else {return nil}
//        return payload.chainId.absoluteString
//    }
//}
