
import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS

struct WCResponse: Codable {
    let topic: String
    let chainId: String?
    let requestMethod: WCRequest.Method
    let requestParams: WCRequest.Params
    let result: JsonRpcResult
}

protocol NetworkInteracting: AnyObject {
    //// TODO - both methods to remove, use Publishers instead
    var onPairingResponse: ((WCResponse) -> Void)? {get set} // Temporary workaround
    var onResponse: ((WCResponse) -> Void)? {get set}
    ///////
    
    var transportConnectionPublisher: AnyPublisher<Void, Never> {get}
    var wcRequestPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {get}
    var responsePublisher: AnyPublisher<WCResponse, Never> {get}
    /// Completes when request sent from a networking client
    func request(_ wcMethod: WCMethod, onTopic topic: String) async throws
    /// Completes with an acknowledgement from the relay network
    func requestNetworkAck(_ wcMethod: WCMethod, onTopic topic: String, completion: @escaping ((Error?) -> ()))
    /// Completes with a peer response
    func requestPeerResponse(_ wcMethod: WCMethod, onTopic topic: String, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>)->())?)
    func respond(topic: String, response: JsonRpcResult, completion: @escaping ((Error?)->()))
    func respondSuccess(for payload: WCRequestSubscriptionPayload)
    func respondError(for payload: WCRequestSubscriptionPayload, reason: ReasonCode)
    func subscribe(topic: String) async throws
    func unsubscribe(topic: String)
}

extension NetworkInteracting {
    func request(_ wcMethod: WCMethod, onTopic topic: String) {
        requestPeerResponse(wcMethod, onTopic: topic, completion: nil)
    }
}

class NetworkInteractor: NetworkInteracting {
    
    var onPairingResponse: ((WCResponse) -> Void)?
    var onResponse: ((WCResponse) -> Void)?
    private var publishers = [AnyCancellable]()

    
    private var networkRelayer: NetworkRelaying
    private let serializer: Serializing
    private let jsonRpcHistory: JsonRpcHistoryRecording
    
    var transportConnectionPublisher: AnyPublisher<Void, Never> {
        transportConnectionPublisherSubject.eraseToAnyPublisher()
    }
    private let transportConnectionPublisherSubject = PassthroughSubject<Void, Never>()
    
    //rename to request publisher
    var wcRequestPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {
        wcRequestPublisherSubject.eraseToAnyPublisher()
    }
    private let wcRequestPublisherSubject = PassthroughSubject<WCRequestSubscriptionPayload, Never>()
    
    var responsePublisher: AnyPublisher<WCResponse, Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }
    private let responsePublisherSubject = PassthroughSubject<WCResponse, Never>()

    let logger: ConsoleLogging
    
    init(networkRelayer: NetworkRelaying,
         serializer: Serializing,
         logger: ConsoleLogging,
         jsonRpcHistory: JsonRpcHistoryRecording) {
        self.networkRelayer = networkRelayer
        self.serializer = serializer
        self.logger = logger
        self.jsonRpcHistory = jsonRpcHistory
        setUpPublishers()
    }
    
    func request(_ wcMethod: WCMethod, onTopic topic: String) async throws {
        try await request(topic: topic, payload: wcMethod.asRequest())
    }
    
    /// Completes when networking client sends a request
    func request(topic: String, payload: WCRequest) async throws {
        try jsonRpcHistory.set(topic: topic, request: payload, chainId: getChainId(payload))
        let message = try serializer.serialize(topic: topic, encodable: payload)
        let prompt = shouldPrompt(payload.method)
        try await networkRelayer.publish(topic: topic, payload: message, prompt: prompt)
    }

    func requestPeerResponse(_ wcMethod: WCMethod, onTopic topic: String, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> ())?) {
        let payload = wcMethod.asRequest()
        do {
            try jsonRpcHistory.set(topic: topic, request: payload, chainId: getChainId(payload))
            let message = try serializer.serialize(topic: topic, encodable: payload)
            let prompt = shouldPrompt(payload.method)
            networkRelayer.publish(topic: topic, payload: message, prompt: prompt) { [weak self] error in
                guard let self = self else {return}
                if let error = error {
                    self.logger.error(error)
                } else {
                    var cancellable: AnyCancellable!
                    cancellable = self.responsePublisher
                        .filter {$0.result.id == payload.id}
                        .sink { (response) in
                            cancellable.cancel()
                            self.logger.debug("WC Relay - received response on topic: \(topic)")
                            switch response.result {
                            case .response(let response):
                                completion?(.success(response))
                            case .error(let error):
                                self.logger.debug("Request error: \(error)")
                                completion?(.failure(error))
                            }
                        }
                }
            }
        } catch WalletConnectError.internal(.jsonRpcDuplicateDetected) {
            logger.info("Info: Json Rpc Duplicate Detected")
        } catch {
            logger.error(error)
        }
    }
    
    /// Completes with an acknowledgement from the relay network.
    /// completes with error if networking client was not able to send a message
    func requestNetworkAck(_ wcMethod: WCMethod, onTopic topic: String, completion: @escaping ((Error?) -> ())) {
        do {
            let payload = wcMethod.asRequest()
            try jsonRpcHistory.set(topic: topic, request: payload, chainId: getChainId(payload))
            let message = try serializer.serialize(topic: topic, encodable: payload)
            let prompt = shouldPrompt(payload.method)
            networkRelayer.publish(topic: topic, payload: message, prompt: prompt) { error in
                completion(error)
            }
        } catch WalletConnectError.internal(.jsonRpcDuplicateDetected) {
            logger.info("Info: Json Rpc Duplicate Detected")
        } catch {
            logger.error(error)
        }
    }

    func respond(topic: String, response: JsonRpcResult, completion: @escaping ((Error?)->())) {
        do {
            _ = try jsonRpcHistory.resolve(response: response)
            let message = try serializer.serialize(topic: topic, encodable: response.value)
            logger.debug("Responding....topic: \(topic)")
            networkRelayer.publish(topic: topic, payload: message, prompt: false) { error in
                completion(error)
            }
        } catch WalletConnectError.internal(.jsonRpcDuplicateDetected) {
            logger.info("Info: Json Rpc Duplicate Detected")
        } catch {
            completion(error)
        }
    }
    
    func respondSuccess(for payload: WCRequestSubscriptionPayload) {
        let response = JSONRPCResponse<AnyCodable>(id: payload.wcRequest.id, result: AnyCodable(true))
        respond(topic: payload.topic, response: JsonRpcResult.response(response)) { _ in } // TODO: Move error handling to relayer package
    }
    
    func respondError(for payload: WCRequestSubscriptionPayload, reason: ReasonCode) {
        let response = JSONRPCErrorResponse(id: payload.wcRequest.id, error: JSONRPCErrorResponse.Error(code: reason.code, message: reason.message))
        respond(topic: payload.topic, response: JsonRpcResult.error(response)) { _ in } // TODO: Move error handling to relayer package
    }
    
    func subscribe(topic: String) async throws {
        try await networkRelayer.subscribe(topic: topic)
    }

    func unsubscribe(topic: String) {
        networkRelayer.unsubscribe(topic: topic) { [weak self] error in
            if let error = error {
                self?.logger.error(error)
            } else {
                self?.jsonRpcHistory.delete(topic: topic)
            }
        }
    }
    
    //MARK: - Private
    private func setUpPublishers() {
        networkRelayer.socketConnectionStatusPublisher.sink { [weak self] status in
            if status == .connected {
                self?.transportConnectionPublisherSubject.send()
            }
        }.store(in: &publishers)
        networkRelayer.onMessage = { [unowned self] topic, message in
            manageSubscription(topic, message)
        }
    }
    
    private func manageSubscription(_ topic: String, _ message: String) {
        if let deserializedJsonRpcRequest: WCRequest = serializer.tryDeserialize(topic: topic, message: message) {
            handleWCRequest(topic: topic, request: deserializedJsonRpcRequest)
        } else if let deserializedJsonRpcResponse: JSONRPCResponse<AnyCodable> = serializer.tryDeserialize(topic: topic, message: message) {
            handleJsonRpcResponse(response: deserializedJsonRpcResponse)
        } else if let deserializedJsonRpcError: JSONRPCErrorResponse = serializer.tryDeserialize(topic: topic, message: message) {
            handleJsonRpcErrorResponse(response: deserializedJsonRpcError)
        } else {
            logger.warn("Warning: WalletConnect Relay - Received unknown object type from networking relay")
        }
    }
    
    private func handleWCRequest(topic: String, request: WCRequest) {
        do {
            try jsonRpcHistory.set(topic: topic, request: request, chainId: getChainId(request))
            let payload = WCRequestSubscriptionPayload(topic: topic, wcRequest: request)
            wcRequestPublisherSubject.send(payload)
        } catch WalletConnectError.internal(.jsonRpcDuplicateDetected) {
            logger.info("Info: Json Rpc Duplicate Detected")
        } catch {
            logger.error(error)
        }
    }
    
    private func handleJsonRpcResponse(response: JSONRPCResponse<AnyCodable>) {
        do {
            let record = try jsonRpcHistory.resolve(response: JsonRpcResult.response(response))
            let wcResponse = WCResponse(
                topic: record.topic,
                chainId: record.chainId,
                requestMethod: record.request.method,
                requestParams: record.request.params,
                result: JsonRpcResult.response(response))
            responsePublisherSubject.send(wcResponse)
            onPairingResponse?(wcResponse)
            onResponse?(wcResponse)
        } catch  {
            logger.info("Info: \(error.localizedDescription)")
        }
    }
    
    private func handleJsonRpcErrorResponse(response: JSONRPCErrorResponse) {
        do {
            let record = try jsonRpcHistory.resolve(response: JsonRpcResult.error(response))
            let wcResponse = WCResponse(
                topic: record.topic,
                chainId: record.chainId,
                requestMethod: record.request.method,
                requestParams: record.request.params,
                result: JsonRpcResult.error(response))
            responsePublisherSubject.send(wcResponse)
            onPairingResponse?(wcResponse)
            onResponse?(wcResponse)
        } catch {
            logger.info("Info: \(error.localizedDescription)")
        }
    }
    
    private func shouldPrompt(_ method: WCRequest.Method) -> Bool {
        switch method {
        case .sessionRequest:
            return true
        default:
            return false
        }
    }
    
    func getChainId(_ request: WCRequest) -> String? {
        guard case let .sessionRequest(payload) = request.params else {return nil}
        return payload.chainId.absoluteString
    }
}
