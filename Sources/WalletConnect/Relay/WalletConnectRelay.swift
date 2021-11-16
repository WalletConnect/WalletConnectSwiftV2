
import Foundation
import Combine

protocol WalletConnectRelaying {
    var transportConnectionPublisher: AnyPublisher<Void, Never> {get}
    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {get}
    func request(topic: String, payload: ClientSynchJSONRPC, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>)->()))
    func respond(topic: String, response: JsonRpcResponseTypes, completion: @escaping ((Error?)->()))
    func subscribe(topic: String)
    func unsubscribe(topic: String)
}

enum JsonRpcResponseTypes: Codable {
    case error(JSONRPCErrorResponse)
    case response(JSONRPCResponse<AnyCodable>)
    var id: Int64 {
        switch self {
        case .error(let value):
            return value.id
        case .response(let value):
            return value.id
        }
    }
    var value: Codable {
        switch self {
        case .error(let value):
            return value
        case .response(let value):
            return value
        }
    }
}

class WalletConnectRelay: WalletConnectRelaying {
    private var networkRelayer: NetworkRelaying
    private let jsonRpcSerialiser: JSONRPCSerialising
    private let jsonRpcHistory: JsonRpcHistoryRecording
    
    var transportConnectionPublisher: AnyPublisher<Void, Never> {
        transportConnectionPublisherSubject.eraseToAnyPublisher()
    }
    private let transportConnectionPublisherSubject = PassthroughSubject<Void, Never>()
    
    //rename to request publisher
    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {
        clientSynchJsonRpcPublisherSubject.eraseToAnyPublisher()
    }
    private let clientSynchJsonRpcPublisherSubject = PassthroughSubject<WCRequestSubscriptionPayload, Never>()
    
    private var wcResponsePublisher: AnyPublisher<JsonRpcResponseTypes, Never> {
        wcResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let wcResponsePublisherSubject = PassthroughSubject<JsonRpcResponseTypes, Never>()
    let logger: BaseLogger
    
    init(networkRelayer: NetworkRelaying,
         jsonRpcSerialiser: JSONRPCSerialising,
         logger: BaseLogger,
         jsonRpcHistory: JsonRpcHistoryRecording) {
        self.networkRelayer = networkRelayer
        self.jsonRpcSerialiser = jsonRpcSerialiser
        self.logger = logger
        self.jsonRpcHistory = jsonRpcHistory
        setUpPublishers()
    }

    func request(topic: String, payload: ClientSynchJSONRPC, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>)->())) {
        do {
            try jsonRpcHistory.set(topic: topic, request: payload)
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
                                completion(.success(response))
                            case .error(let error):
                                completion(.failure(error))
                            }
                        }
                }
            }
        } catch {
            logger.error(error)
        }
    }
    
    func respond(topic: String, response: JsonRpcResponseTypes, completion: @escaping ((Error?)->())) {
        do {
            try jsonRpcHistory.resolve(response: response)
            let message = try jsonRpcSerialiser.serialise(topic: topic, encodable: response.value)
            logger.debug("Responding....topic: \(topic)")
            networkRelayer.publish(topic: topic, payload: message) { [weak self] error in
                completion(error)
            }
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
        if let deserialisedJsonRpcRequest: ClientSynchJSONRPC = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            handleWCRequest(topic: topic, request: deserialisedJsonRpcRequest)
        } else if let deserialisedJsonRpcResponse: JSONRPCResponse<AnyCodable> = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            handleJsonRpcResponse(response: deserialisedJsonRpcResponse)
        } else if let deserialisedJsonRpcError: JSONRPCErrorResponse = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            handleJsonRpcErrorResponse(response: deserialisedJsonRpcError)
        }
    }
    
    private func handleWCRequest(topic: String, request: ClientSynchJSONRPC) {
        do {
            try jsonRpcHistory.set(topic: topic, request: request)
            let payload = WCRequestSubscriptionPayload(topic: topic, clientSynchJsonRpc: request)
            clientSynchJsonRpcPublisherSubject.send(payload)
        } catch {
            logger.error(error)
        }
    }
    
    private func handleJsonRpcResponse(response: JSONRPCResponse<AnyCodable>) {
        do {
            try jsonRpcHistory.resolve(response: JsonRpcResponseTypes.response(response))
            wcResponsePublisherSubject.send(.response(response))
        } catch {
            logger.error(error)
        }
    }
    
    private func handleJsonRpcErrorResponse(response: JSONRPCErrorResponse) {
        do {
            try jsonRpcHistory.resolve(response: JsonRpcResponseTypes.error(response))
            wcResponsePublisherSubject.send(.error(response))
        } catch {
            logger.error(error)
        }
    }
}
