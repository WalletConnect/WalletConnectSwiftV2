
import Foundation
import Combine

protocol WalletConnectRelaying {
    var transportConnectionPublisher: AnyPublisher<Void, Never> {get}
    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {get}
    func publish(topic: String, payload: Encodable, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, JSONRPCError>)->()))
    func subscribe(topic: String)
    func unsubscribe(topic: String)
}

enum WCResponse {
    case error((topic: String, value: JSONRPCError))
    case response((topic: String, value: JSONRPCResponse<AnyCodable>))
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
    private let crypto: Crypto
    
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
    
    init(networkRelayer: NetworkRelaying,
         jsonRpcSerialiser: JSONRPCSerialising = JSONRPCSerialiser(),
         crypto: Crypto) {
        self.networkRelayer = networkRelayer
        self.jsonRpcSerialiser = jsonRpcSerialiser
        self.crypto = crypto
        setUpPublishers()
    }

    func publish(topic: String, payload: Encodable, completion: @escaping ((Result<JSONRPCResponse<AnyCodable>, JSONRPCError>)->())) {
        do {
            let message = try serialise(topic: topic, jsonRpc: payload)
            networkRelayer.publish(topic: topic, payload: message) { [weak self] error in
                guard let self = self else {return}
                if let error = error {
                    Logger.error(error)
                } else {
                    var cancellable: AnyCancellable!
                    cancellable = self.wcResponsePublisher
                        .filter {$0.topic == topic}
                        .sink { (response) in
                            cancellable.cancel()
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
            Logger.error(error)
        }
    }
    
    func subscribe(topic: String)  {
        networkRelayer.subscribe(topic: topic) { error in
            if let error = error {
                Logger.error(error)
            }
        }
    }

    func unsubscribe(topic: String) {
        networkRelayer.unsubscribe(topic: topic) { error in
            if let error = error {
                Logger.error(error)
            }
        }
    }
    
    //MARK: - Private
    
    private func setUpPublishers() {
        networkRelayer.onConnect = {
            self.transportConnectionPublisherSubject.send()
        }
        networkRelayer.onMessage = { [weak self] topic, message in
            self?.manageSubscription(topic, message)
        }
    }
    
    private func manageSubscription(_ topic: String, _ message: String) {
        if let deserialisedJsonRpcRequest: ClientSynchJSONRPC = tryDeserialise(topic: topic, message: message) {
            let payload = WCRequestSubscriptionPayload(topic: topic, clientSynchJsonRpc: deserialisedJsonRpcRequest)
            clientSynchJsonRpcPublisherSubject.send(payload)
        } else if let deserialisedJsonRpcResponse: JSONRPCResponse<AnyCodable> = tryDeserialise(topic: topic, message: message) {
            wcResponsePublisherSubject.send(.response((topic, deserialisedJsonRpcResponse)))
        } else if let deserialisedJsonRpcError: JSONRPCError = tryDeserialise(topic: topic, message: message) {
            wcResponsePublisherSubject.send(.error((topic, deserialisedJsonRpcError)))
        }
    }
    
    private func tryDeserialise<T: Codable>(topic: String, message: String) -> T? {
        do {
            let deserialisedJsonRpcRequest: T
            if let agreementKeys = crypto.getAgreementKeys(for: topic) {
                deserialisedJsonRpcRequest = try jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret)
            } else {
                let jsonData = Data(hex: message)
                deserialisedJsonRpcRequest = try JSONDecoder().decode(T.self, from: jsonData)
            }
            return deserialisedJsonRpcRequest
        } catch {
            Logger.error(error)
            return nil
        }
    }
    
    private func serialise(topic: String, jsonRpc: Encodable) throws -> String {
        let messageJson = try jsonRpc.json()
        var message: String
        if let agreementKeys = crypto.getAgreementKeys(for: topic) {
            message = try jsonRpcSerialiser.serialise(json: messageJson, agreementKeys: agreementKeys)
        } else {
            message = messageJson.toHexEncodedString(uppercase: false)
        }
        return message
    }
    
    private func deserialiseJsonRpc(topic: String, message: String) throws -> Result<JSONRPCResponse<AnyCodable>, JSONRPCError> {
        guard let agreementKeys = crypto.getAgreementKeys(for: topic) else {
            throw WalletConnectError.keyNotFound
        }
        if let jsonrpcResponse: JSONRPCResponse<AnyCodable> = try? jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret) {
            return .success(jsonrpcResponse)
        } else if let jsonrpcError: JSONRPCError = try? jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret) {
            return .failure(jsonrpcError)
        }
        throw WalletConnectError.deserialisationFailed
    }
}
