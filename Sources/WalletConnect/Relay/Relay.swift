
//
//import Foundation
//import Combine
//
//protocol Relaying {
//    var wcResponsePublisher: AnyPublisher<JSONRPCResponse<String>, Never> {get}
//    var transportConnectionPublisher: AnyPublisher<Void, Never> {get}
//    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {get}
//    /// - returns: request id
//    func publish(topic: String, payload: Encodable, completion: @escaping ((Result<Void, Error>)->())) throws -> Int64
//    /// - returns: request id
//    func subscribe(topic: String, completion: @escaping ((Result<String, Error>)->())) throws -> Int64
//    /// - returns: request id
//    func unsubscribe(topic: String, id: String, completion: @escaping ((Result<Void, Error>)->())) throws -> Int64
//}
//
//class Relay: Relaying {
//    private typealias SubscriptionRequest = JSONRPCRequest<RelayJSONRPC.SubscriptionParams>
//    private typealias SubscriptionResponse = JSONRPCResponse<String>
//    private typealias RequestAcknowledgement = JSONRPCResponse<Bool>
//
//    // ttl for waku network to persist message for peer client in case request is not acknowledged
//    private let defaultTtl = 6*Time.hour
//    private let jsonRpcSerialiser: JSONRPCSerialising
//    private var transport: JSONRPCTransporting
//    private let crypto: Crypto
//    private var subscriptionResponsePublisher: AnyPublisher<JSONRPCResponse<String>, Never> {
//        subscriptionResponsePublisherSubject.eraseToAnyPublisher()
//    }
//    private let subscriptionResponsePublisherSubject = PassthroughSubject<JSONRPCResponse<String>, Never>()
//    private var requestAcknowledgePublisher: AnyPublisher<JSONRPCResponse<Bool>, Never> {
//        requestAcknowledgePublisherSubject.eraseToAnyPublisher()
//    }
//    private let requestAcknowledgePublisherSubject = PassthroughSubject<JSONRPCResponse<Bool>, Never>()
//    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {
//        clientSynchJsonRpcPublisherSubject.eraseToAnyPublisher()
//    }
//    private let clientSynchJsonRpcPublisherSubject = PassthroughSubject<WCRequestSubscriptionPayload, Never>()
//    
//    var wcResponsePublisher: AnyPublisher<JSONRPCResponse<String>, Never> {
//        wcResponsePublisherSubject.eraseToAnyPublisher()
//    }
//    private let wcResponsePublisherSubject = PassthroughSubject<JSONRPCResponse<String>, Never>()
//    
//    
//    var transportConnectionPublisher: AnyPublisher<Void, Never> {
//        transportConnectionPublisherSubject.eraseToAnyPublisher()
//    }
//    private let transportConnectionPublisherSubject = PassthroughSubject<Void, Never>()
//    
//    private var payloadCancellable: AnyCancellable?
//    
//    init(jsonRpcSerialiser: JSONRPCSerialising = JSONRPCSerialiser(),
//         transport: JSONRPCTransporting,
//         crypto: Crypto) {
//        self.jsonRpcSerialiser = jsonRpcSerialiser
//        self.transport = transport
//        self.crypto = crypto
//        setUpBindings()
//    }
//
//    private func setUpBindings() {
//        transport.onMessage = { [weak self] payload in
//            self?.handlePayloadMessage(payload)
//        }
//        transport.onConnect = { [unowned self] in
//            self.transportConnectionPublisherSubject.send()
//        }
//    }
//    
//    @discardableResult func publish(topic: String, payload: Encodable, completion: @escaping ((Result<Void, Error>)->())) throws -> Int64 {
//        let messageJson = try payload.json()
//        var message: String
//        if let agreementKeys = crypto.getAgreementKeys(for: topic) {
//            message = try jsonRpcSerialiser.serialise(json: messageJson, agreementKeys: agreementKeys)
//        } else {
//            message = messageJson.toHexEncodedString(uppercase: false)
//        }
//        let params = RelayJSONRPC.PublishParams(topic: topic, message: message, ttl: defaultTtl)
//        let request = JSONRPCRequest<RelayJSONRPC.PublishParams>(method: RelayJSONRPC.Method.publish.rawValue, params: params)
//        let requestJson = try request.json()
//        Logger.debug("Publishing Payload on Topic: \(topic)")
//        var cancellable: AnyCancellable!
//        transport.send(requestJson) { error in
//            if let error = error {
//                Logger.debug("Failed to Publish Payload")
//                Logger.error(error)
//                cancellable.cancel()
//                completion(.failure(error))
//            }
//        }
//        cancellable = requestAcknowledgePublisher
//            .filter {$0.id == request.id}
//            .sink { (subscriptionResponse) in
//            cancellable.cancel()
//                completion(.success(()))
//        }
//        return request.id
//    }
//    
//    func subscribe(topic: String, completion: @escaping ((Result<String, Error>)->())) throws -> Int64 {
//        Logger.debug("Subscribing on Topic: \(topic)")
//        let params = RelayJSONRPC.SubscribeParams(topic: topic)
//        let request = JSONRPCRequest(method: RelayJSONRPC.Method.subscribe.rawValue, params: params)
//        let requestJson = try request.json()
//        var cancellable: AnyCancellable!
//        transport.send(requestJson) { error in
//            if let error = error {
//                Logger.debug("Failed to Subscribe on Topic")
//                Logger.error(error)
//                cancellable.cancel()
//                completion(.failure(error))
//            }
//        }
//        cancellable = subscriptionResponsePublisher
//            .filter {$0.id == request.id}
//            .sink { (subscriptionResponse) in
//            cancellable.cancel()
//                completion(.success(subscriptionResponse.result))
//        }
//        return request.id
//    }
//    
//    func unsubscribe(topic: String, id: String, completion: @escaping ((Result<Void, Error>)->())) async throws -> Int64 {
//        Logger.debug("Unsubscribing on Topic: \(topic)")
//        let params = RelayJSONRPC.UnsubscribeParams(id: id, topic: topic)
//        let request = JSONRPCRequest(method: RelayJSONRPC.Method.unsubscribe.rawValue, params: params)
//        let requestJson = try request.json()
//        var cancellable: AnyCancellable!
//        transport.send(requestJson) { error in
//            if let error = error {
//                Logger.debug("Failed to Unsubscribe on Topic")
//                Logger.error(error)
//                cancellable.cancel()
//                completion(.failure(error))
//            }
//        }
//        cancellable = requestAcknowledgePublisher
//            .filter {$0.id == request.id}
//            .sink { (subscriptionResponse) in
//                cancellable.cancel()
//                completion(.success(()))
//            }
//        return request.id
//    }
//
//    private func handlePayloadMessage(_ payload: String) {
//        if let request = tryDecode(SubscriptionRequest.self, from: payload),
//           request.method == RelayJSONRPC.Method.subscription.rawValue {
//            manageSubscriptionRequest(request)
//        } else if let response = tryDecode(RequestAcknowledgement.self, from: payload) {
//            requestAcknowledgePublisherSubject.send(response)
//        } else if let response = tryDecode(SubscriptionResponse.self, from: payload) {
//            subscriptionResponsePublisherSubject.send(response)
//        } else if let response = tryDecode(JSONRPCError.self, from: payload) {
//            Logger.error("Received error message from network, code: \(response.code), message: \(response.message)")
//        } else {
//            Logger.error("Unexpected response from network")
//        }
//    }
//    
//    private func tryDecode<T: Decodable>(_ type: T.Type, from payload: String) -> T? {
//        if let data = payload.data(using: .utf8),
//           let response = try? JSONDecoder().decode(T.self, from: data) {
//            return response
//        } else {
//            return nil
//        }
//    }
//    
//    private func manageSubscriptionRequest(_ request: JSONRPCRequest<RelayJSONRPC.SubscriptionParams>) {
//        let topic = request.params.data.topic
//        let message = request.params.data.message
//        if let deserialisedJsonRpcRequest = deserialiseWCRequest(topic: topic, message: message) {
//            let payload = WCRequestSubscriptionPayload(topic: topic, subscriptionId: request.params.id, clientSynchJsonRpc: deserialisedJsonRpcRequest)
//            clientSynchJsonRpcPublisherSubject.send(payload)
//        } else if let deserialisedJsonRpcResponse = deserialiseWCResponse(topic: topic, message: message) {
//            wcResponsePublisherSubject.send(deserialisedJsonRpcResponse)
//        }
//        acknowledgeSubscription(requestId: request.id)
//    }
//    
//    private func deserialiseWCRequest(topic: String, message: String) -> ClientSynchJSONRPC? {
//        do {
//            let deserialisedJsonRpcRequest: ClientSynchJSONRPC
//            if let agreementKeys = crypto.getAgreementKeys(for: topic) {
//                deserialisedJsonRpcRequest = try jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret)
//            } else {
//                let jsonData = Data(hex: message)
//                deserialisedJsonRpcRequest = try JSONDecoder().decode(ClientSynchJSONRPC.self, from: jsonData)
//            }
//            return deserialisedJsonRpcRequest
//        } catch {
//            Logger.error(error)
//            return nil
//        }
//    }
//    
//    private func deserialiseWCResponse(topic: String, message: String) -> JSONRPCResponse<String>? {
//        guard let agreementKeys = crypto.getAgreementKeys(for: topic) else {
//            return nil
//        }
//        return try? jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret)
//    }
//    
//    private func acknowledgeSubscription(requestId: Int64) {
//        let response = JSONRPCResponse(id: requestId, result: true)
//        let responseJson = try! response.json()
//        transport.send(responseJson) { error in
//            if let error = error {
//                Logger.debug("Failed to Respond for request id: \(requestId)")
//                Logger.error(error)
//            }
//        }
//    }
//}
