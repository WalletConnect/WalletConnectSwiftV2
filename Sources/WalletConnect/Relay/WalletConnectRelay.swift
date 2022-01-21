
import Foundation
import Combine
import WalletConnectUtils

struct WCResponse {
    let topic: String
    let requestMethod: WCRequest.Method
    let requestParams: WCRequest.Params
    let result: Result<JSONRPCResponse<AnyCodable>, Error>
}

protocol WalletConnectRelaying: AnyObject {
    var onPairingResponse: ((WCResponse) -> Void)? {get set} // Temporary workaround
    var onResponse: ((WCResponse) -> Void)? {get set}
    var transportConnectionPublisher: AnyPublisher<Void, Never> {get}
    var wcRequestPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {get}
    func request(_ wcMethod: WCMethod, onTopic topic: String, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>)->())?)
    func request(topic: String, payload: WCRequest, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>)->())?) 
    func respond(topic: String, response: JsonRpcResponseTypes, completion: @escaping ((Error?)->()))
    func subscribe(topic: String)
    func unsubscribe(topic: String)
}

extension WalletConnectRelaying {
    func request(_ wcMethod: WCMethod, onTopic topic: String) {
        request(wcMethod, onTopic: topic, completion: nil)
    }
}

class WalletConnectRelay: WalletConnectRelaying {
    
    var onPairingResponse: ((WCResponse) -> Void)?
    var onResponse: ((WCResponse) -> Void)?
    
    private var networkRelayer: NetworkRelaying
    private let jsonRpcSerialiser: JSONRPCSerialising
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
    
    private var wcResponsePublisher: AnyPublisher<JsonRpcResponseTypes, Never> {
        wcResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let wcResponsePublisherSubject = PassthroughSubject<JsonRpcResponseTypes, Never>()
    let logger: ConsoleLogging
    
    init(networkRelayer: NetworkRelaying,
         jsonRpcSerialiser: JSONRPCSerialising,
         logger: ConsoleLogging,
         jsonRpcHistory: JsonRpcHistoryRecording) {
        self.networkRelayer = networkRelayer
        self.jsonRpcSerialiser = jsonRpcSerialiser
        self.logger = logger
        self.jsonRpcHistory = jsonRpcHistory
        setUpPublishers()
    }
    
    func request(_ wcMethod: WCMethod, onTopic topic: String, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>) -> ())?) {
        request(topic: topic, payload: wcMethod.asRequest(), completion: completion)
    }
    
    func request(topic: String, payload: WCRequest, completion: ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>)->())?) {
        do {
            try jsonRpcHistory.set(topic: topic, request: payload, chainId: getChainId(payload))
            let message = try jsonRpcSerialiser.serialise(topic: topic, encodable: payload)
            networkRelayer.publish(topic: topic, payload: message) { [weak self] error in
                guard let self = self else {return}
                if let error = error {
                    self.logger.error(error)
                } else {
                    var cancellable: AnyCancellable!
                    cancellable = self.wcResponsePublisher
                        .filter {$0.id == payload.id}
                        .sink { (response) in
                            cancellable.cancel()
                            self.logger.debug("WC Relay - received response on topic: \(topic)")
                            switch response {
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
    
    func respond(topic: String, response: JsonRpcResponseTypes, completion: @escaping ((Error?)->())) {
        do {
            _ = try jsonRpcHistory.resolve(response: response)
            let message = try jsonRpcSerialiser.serialise(topic: topic, encodable: response.value)
            logger.debug("Responding....topic: \(topic)")
            networkRelayer.publish(topic: topic, payload: message) { error in
                completion(error)
            }
        } catch WalletConnectError.internal(.jsonRpcDuplicateDetected) {
            logger.info("Info: Json Rpc Duplicate Detected")
        } catch {
            completion(error)
        }
    }
    
    func subscribe(topic: String)  {
        networkRelayer.subscribe(topic: topic) { [weak self] error in
            if let error = error {
                self?.logger.error(error)
            }
        }
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
        networkRelayer.onConnect = { [weak self] in
            self?.transportConnectionPublisherSubject.send()
        }
        networkRelayer.onMessage = { [unowned self] topic, message in
            manageSubscription(topic, message)
        }
    }
    
    private func manageSubscription(_ topic: String, _ message: String) {
        if let deserialisedJsonRpcRequest: WCRequest = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            handleWCRequest(topic: topic, request: deserialisedJsonRpcRequest)
        } else if let deserialisedJsonRpcResponse: JSONRPCResponse<AnyCodable> = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            handleJsonRpcResponse(response: deserialisedJsonRpcResponse)
        } else if let deserialisedJsonRpcError: JSONRPCErrorResponse = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            handleJsonRpcErrorResponse(response: deserialisedJsonRpcError)
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
            let record = try jsonRpcHistory.resolve(response: JsonRpcResponseTypes.response(response))
            let wcResponse = WCResponse(
                topic: record.topic,
                requestMethod: record.request.method,
                requestParams: record.request.params,
                result: .success(response))
            wcResponsePublisherSubject.send(.response(response))
            onPairingResponse?(wcResponse)
            onResponse?(wcResponse)
        } catch  {
            logger.info("Info: \(error.localizedDescription)")
        }
    }
    
    private func handleJsonRpcErrorResponse(response: JSONRPCErrorResponse) {
        do {
            let record = try jsonRpcHistory.resolve(response: JsonRpcResponseTypes.error(response))
            let wcResponse = WCResponse(
                topic: record.topic,
                requestMethod: record.request.method,
                requestParams: record.request.params,
                result: .failure(response))
            wcResponsePublisherSubject.send(.error(response))
            onPairingResponse?(wcResponse)
            onResponse?(wcResponse)
        } catch {
            logger.info("Info: \(error.localizedDescription)")
        }
    }
    
    func getChainId(_ request: WCRequest) -> String? {
        guard case let .sessionPayload(payload) = request.params else {return nil}
        return payload.chainId
    }
}
