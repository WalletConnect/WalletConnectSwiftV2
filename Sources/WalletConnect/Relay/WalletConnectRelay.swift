
import Foundation
import Combine

protocol WalletConnectRelaying {
    var transportConnectionPublisher: AnyPublisher<Void, Never> {get}
    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {get}
    func request(topic: String, payload: ClientSynchJSONRPC, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, JSONRPCError>)->()))
    func respond(topic: String, payload: Encodable, completion: @escaping ((Error?)->()))
    func subscribe(topic: String)
    func unsubscribe(topic: String)
}

enum WCResponse {
    case error((topic: String, value: JSONRPCError))
    case response((topic: String, value: JSONRPCResponse<AnyCodable>))
    var id: Int64 {
        switch self {
        case .error(let value):
            fatalError("not implemented")
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
    var history = [String]()
    
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
         logger: BaseLogger) {
        self.networkRelayer = networkRelayer
        self.jsonRpcSerialiser = jsonRpcSerialiser
        self.logger = logger
        setUpPublishers()
    }

    func request(topic: String, payload: ClientSynchJSONRPC, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, JSONRPCError>)->())) {
        do {
//            let message = try serialise(topic: topic, jsonRpc: payload)
            let message = try jsonRpcSerialiser.serialise(topic: topic, encodable: payload)
            history.append(message)
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
//        let message = try! serialise(topic: topic, jsonRpc: payload)
        let message = try! jsonRpcSerialiser.serialise(topic: topic, encodable: payload)
        history.append(message)
        logger.debug("Responding....topic: \(topic)")
        networkRelayer.publish(topic: topic, payload: message) { [weak self] error in
            self?.logger.debug("responded")
            //TODO
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
    let serialQueue = DispatchQueue(label: UUID().uuidString)
    private func setUpPublishers() {
        networkRelayer.onConnect = { [weak self] in
            self?.transportConnectionPublisherSubject.send()
        }
        networkRelayer.onMessage = { [unowned self] topic, message in
            serialQueue.sync {
                if self.history.contains(message) {
                    print("duplicate: \(message)")
                    return
                } else {
                    self.history.append(message)
                    self.manageSubscription(topic, message)
                }
            }
        }
    }
    
    private func manageSubscription(_ topic: String, _ message: String) {
        if let deserialisedJsonRpcRequest: ClientSynchJSONRPC = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            let payload = WCRequestSubscriptionPayload(topic: topic, clientSynchJsonRpc: deserialisedJsonRpcRequest)
            if payload.clientSynchJsonRpc.method == .pairingPayload {
                clientSynchJsonRpcPublisherSubject.send(payload)
            } else {
                clientSynchJsonRpcPublisherSubject.send(payload)
            }
        } else if let deserialisedJsonRpcResponse: JSONRPCResponse<AnyCodable> = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            wcResponsePublisherSubject.send(.response((topic, deserialisedJsonRpcResponse)))
        } else if let deserialisedJsonRpcError: JSONRPCError = jsonRpcSerialiser.tryDeserialise(topic: topic, message: message) {
            wcResponsePublisherSubject.send(.error((topic, deserialisedJsonRpcError)))
        }
    }
    
//    private func tryDeserialise<T: Codable>(topic: String, message: String) -> T? {
//        do {
//            let deserialisedJsonRpcRequest: T
//            if let agreementKeys = crypto.getAgreementKeys(for: topic) {
//                deserialisedJsonRpcRequest = try jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret)
//            } else {
//                let jsonData = Data(hex: message)
//                deserialisedJsonRpcRequest = try JSONDecoder().decode(T.self, from: jsonData)
//            }
//            return deserialisedJsonRpcRequest
//        } catch {
//            logger.debug("Type \(T.self) does not match the payload")
//            return nil
//        }
//    }
//
//    private func serialise(topic: String, jsonRpc: Encodable) throws -> String {
//        let messageJson = try jsonRpc.json()
//        var message: String
//        if let agreementKeys = crypto.getAgreementKeys(for: topic) {
//            message = try jsonRpcSerialiser.serialise(json: messageJson, agreementKeys: agreementKeys)
//        } else {
//            message = messageJson.toHexEncodedString(uppercase: false)
//        }
//        return message
//    }
//
//    private func deserialiseJsonRpc(topic: String, message: String) throws -> Result<JSONRPCResponse<AnyCodable>, JSONRPCError> {
//        guard let agreementKeys = crypto.getAgreementKeys(for: topic) else {
//            throw WalletConnectError.internal(.keyNotFound)
//        }
//        if let jsonrpcResponse: JSONRPCResponse<AnyCodable> = try? jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret) {
//            return .success(jsonrpcResponse)
//        } else if let jsonrpcError: JSONRPCError = try? jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret) {
//            return .failure(jsonrpcError)
//        }
//        throw WalletConnectError.internal(.deserialisationFailed)
//    }
}
