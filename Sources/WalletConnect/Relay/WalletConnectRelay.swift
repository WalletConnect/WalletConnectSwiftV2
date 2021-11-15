
import Foundation
import Combine

protocol WalletConnectRelaying {
    var transportConnectionPublisher: AnyPublisher<Void, Never> {get}
    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {get}
    func request(topic: String, payload: ClientSynchJSONRPC, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>)->()))
    func respond(topic: String, payload: Encodable, completion: @escaping ((Error?)->()))
    func subscribe(topic: String)
    func unsubscribe(topic: String)
}

enum WCResponse {
    case error((topic: String, value: JSONRPCErrorResponse))
    case response((topic: String, value: JSONRPCResponse<AnyCodable>))
    var id: Int64 {
        switch self {
        case .error(let value):
            return value.value.id
        case .response(let value):
            return value.value.id
        }
    }
    var topic: String {
        switch self {
        case .error(let value):
            return value.topic
        case .response(let value):
            return value.topic
        }
    }
}

class WalletConnectRelay: WalletConnectRelaying {
    private var networkRelayer: NetworkRelaying
    private let jsonRpcSerialiser: JSONRPCSerialising
    private let jsonRpcHistory: JsonRpcHistory
    
    var transportConnectionPublisher: AnyPublisher<Void, Never> {
        transportConnectionPublisherSubject.eraseToAnyPublisher()
    }
    private let transportConnectionPublisherSubject = PassthroughSubject<Void, Never>()
    
    //rename to request publisher
    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {
        clientSynchJsonRpcPublisherSubject.eraseToAnyPublisher()
    }
    private let clientSynchJsonRpcPublisherSubject = PassthroughSubject<WCRequestSubscriptionPayload, Never>()
    
    private var wcResponsePublisher: AnyPublisher<WCResponse, Never> {
        wcResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let wcResponsePublisherSubject = PassthroughSubject<WCResponse, Never>()
    let logger: BaseLogger
    
    init(networkRelayer: NetworkRelaying,
         jsonRpcSerialiser: JSONRPCSerialising,
         logger: BaseLogger,
         keyValueStorage: KeyValueStorage) {
        self.networkRelayer = networkRelayer
        self.jsonRpcSerialiser = jsonRpcSerialiser
        self.logger = logger
        self.jsonRpcHistory = JsonRpcHistory(logger: logger, keyValueStorage: RuntimeKeyValueStorage())
        setUpPublishers()
    }

    func request(topic: String, payload: ClientSynchJSONRPC, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, JSONRPCErrorResponse>)->())) {
        do {
            try jsonRpcHistory.set(topic: topic, request: payload.jsonRpcRequestRepresentation(), chainId: "") //todo - chain id
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
                                completion(.success(response.value))
                            case .error(let error):
                                completion(.failure(error.value))
                            }
                        }
                }
            }
        } catch {
            logger.error(error)
        }
    }
    
    func respond(topic: String, payload: Encodable, completion: @escaping ((Error?)->())) {
        do {
            try jsonRpcHistory.resolve(response: <#T##JsonRpcRecord.Response#>)
            let message = try jsonRpcSerialiser.serialise(topic: topic, encodable: payload)
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
            do {
                try jsonRpcHistory.set(topic: topic, request: deserialisedJsonRpcRequest.jsonRpcRequestRepresentation(), chainId: "") // fix chain id
                let payload = WCRequestSubscriptionPayload(topic: topic, clientSynchJsonRpc: deserialisedJsonRpcRequest)
                clientSynchJsonRpcPublisherSubject.send(payload)
            } catch {
                logger.error(error)
            }
        } else if let deserialisedJsonRpcResponse: JSONRPCResponse<AnyCodable> = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            do {
                try jsonRpcHistory.resolve(response: JsonRpcRecord.Response.response(deserialisedJsonRpcResponse))
                wcResponsePublisherSubject.send(.response((topic, deserialisedJsonRpcResponse)))
            } catch {
                logger.error(error)
            }
        } else if let deserialisedJsonRpcError: JSONRPCErrorResponse = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            do {
                try jsonRpcHistory.resolve(response: JsonRpcRecord.Response.error(deserialisedJsonRpcError))
                wcResponsePublisherSubject.send(.error((topic, deserialisedJsonRpcError)))
            } catch {
                logger.error(error)
            }
        }
    }
}
